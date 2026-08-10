import type { BoardSize, GameState, Move, PlayResult, Player, Point, Stone } from './types'

export function idx(size: number, x: number, y: number): number {
  return y * size + x
}

export function inBounds(size: number, x: number, y: number): boolean {
  return x >= 0 && y >= 0 && x < size && y < size
}

/** 한 문자에 담는 교차점 수 — 6칸 × 2비트 = 12비트(0..4095) */
const HASH_PACK = 6
/** 서로게이트 영역(0xD800~)을 피하려는 오프셋 — localStorage·JSON 안전 */
const HASH_BASE = 0x30

/**
 * 위치 해시. 돌 하나를 2비트로 보고 6칸씩 묶어 한 문자로 압축한다.
 * 19줄에서 361자 → 61자 (약 6배). 착수 시도마다 만들어지므로 할당량이 곧 성능이다.
 */
export function boardHash(board: Stone[]): string {
  let out = ''
  for (let i = 0; i < board.length; i += HASH_PACK) {
    let code = 0
    for (let j = 0; j < HASH_PACK; j++) {
      code = (code << 2) | (board[i + j] ?? 0)
    }
    out += String.fromCharCode(HASH_BASE + code)
  }
  return out
}

/**
 * state별 위치 해시 집합 캐시.
 * `legalMoves`는 같은 state로 n²번 `tryPlay`를 부르는데, 예전엔 매번
 * `positionHashes.includes()` 선형 탐색을 했다. 집합은 state당 한 번만 만든다.
 */
const hashSetCache = new WeakMap<GameState, Set<string>>()

function seenHashes(state: GameState): Set<string> {
  let set = hashSetCache.get(state)
  if (!set) {
    set = new Set(state.positionHashes ?? [boardHash(state.board)])
    hashSetCache.set(state, set)
  }
  return set
}

/** history를 처음부터 재생 — 저장된 board·해시를 믿지 않는 정본 계산 */
export function replayHistory(size: BoardSize, history: Move[]): GameState {
  let cur = createGame(size)
  // 첫 수가 백이면(접바둑 등) 차례를 맞춰서 시작
  if (history.length > 0) cur.toPlay = history[0].player
  for (const m of history) {
    const r = m.pass ? pass(cur) : tryPlay(cur, m.x, m.y)
    if (!r.ok) break
    cur = r.state
  }
  return cur
}

/**
 * 저장된 `positionHashes`를 믿지 않고 history에서 다시 만든다.
 * 해시 형식이 바뀌었거나 스냅샷이 오래된 경우에도 슈퍼코 판정이 맞게 유지된다.
 * `ended`·`resignedBy` 같은 history 밖 정보는 원본을 그대로 둔다.
 */
export function rebuildPositionHashes(state: GameState): GameState {
  const replayed = replayHistory(state.size, state.history)
  return { ...cloneState(state), positionHashes: replayed.positionHashes }
}

export function createGame(size: BoardSize = 19): GameState {
  const board = Array<Stone>(size * size).fill(0)
  return {
    size,
    board,
    toPlay: 1,
    captures: { 1: 0, 2: 0 },
    history: [],
    koPoint: null,
    positionHashes: [boardHash(board)],
    consecutivePasses: 0,
    ended: false,
    resignedBy: null,
  }
}

export function cloneState(state: GameState): GameState {
  return {
    ...state,
    board: state.board.slice(),
    captures: { ...state.captures },
    history: state.history.slice(),
    positionHashes: state.positionHashes.slice(),
    koPoint: state.koPoint ? { ...state.koPoint } : null,
  }
}

export function resign(state: GameState, player: Player): GameState {
  const next = cloneState(state)
  next.ended = true
  next.resignedBy = player
  return next
}

function neighbors(size: number, x: number, y: number): Point[] {
  const out: Point[] = []
  if (x > 0) out.push({ x: x - 1, y })
  if (x < size - 1) out.push({ x: x + 1, y })
  if (y > 0) out.push({ x, y: y - 1 })
  if (y < size - 1) out.push({ x, y: y + 1 })
  return out
}

function groupAndLibs(
  board: Stone[],
  size: number,
  sx: number,
  sy: number,
): { stones: Point[]; libs: Point[] } {
  const color = board[idx(size, sx, sy)]
  if (color === 0) return { stones: [], libs: [] }

  const stones: Point[] = []
  const libs: Point[] = []
  const seenStone = new Set<number>()
  const seenLib = new Set<number>()
  const stack: Point[] = [{ x: sx, y: sy }]

  while (stack.length) {
    const p = stack.pop()!
    const i = idx(size, p.x, p.y)
    if (seenStone.has(i)) continue
    seenStone.add(i)
    stones.push(p)

    for (const n of neighbors(size, p.x, p.y)) {
      const ni = idx(size, n.x, n.y)
      const v = board[ni]
      if (v === 0) {
        if (!seenLib.has(ni)) {
          seenLib.add(ni)
          libs.push(n)
        }
      } else if (v === color && !seenStone.has(ni)) {
        stack.push(n)
      }
    }
  }

  return { stones, libs }
}

export function opposite(p: Player): Player {
  return p === 1 ? 2 : 1
}

export function legalMoves(state: GameState): Point[] {
  const moves: Point[] = []
  for (let y = 0; y < state.size; y++) {
    for (let x = 0; x < state.size; x++) {
      if (tryPlay(state, x, y).ok) moves.push({ x, y })
    }
  }
  return moves
}

export function tryPlay(state: GameState, x: number, y: number): PlayResult {
  if (state.ended) return { ok: false, reason: 'game_ended' }
  if (!inBounds(state.size, x, y)) return { ok: false, reason: 'oob' }
  if (state.board[idx(state.size, x, y)] !== 0) return { ok: false, reason: 'occupied' }
  if (state.koPoint && state.koPoint.x === x && state.koPoint.y === y) {
    return { ok: false, reason: 'ko' }
  }

  const next = cloneState(state)
  const player = state.toPlay
  const opp = opposite(player)
  next.board[idx(next.size, x, y)] = player

  const captured: Point[] = []
  for (const n of neighbors(next.size, x, y)) {
    if (next.board[idx(next.size, n.x, n.y)] !== opp) continue
    const g = groupAndLibs(next.board, next.size, n.x, n.y)
    if (g.libs.length === 0) {
      for (const s of g.stones) {
        next.board[idx(next.size, s.x, s.y)] = 0
        captured.push(s)
      }
    }
  }

  const own = groupAndLibs(next.board, next.size, x, y)
  if (own.libs.length === 0) return { ok: false, reason: 'suicide' }

  const hash = boardHash(next.board)
  if (seenHashes(state).has(hash)) {
    return { ok: false, reason: 'superko' }
  }
  const hashes = state.positionHashes ?? [boardHash(state.board)]

  let koPoint: Point | null = null
  if (captured.length === 1) {
    const after = groupAndLibs(next.board, next.size, x, y)
    if (after.stones.length === 1 && after.libs.length === 1) {
      koPoint = captured[0]
    }
  }

  const move: Move = { player, x, y, captured }
  next.captures[player] += captured.length
  next.history.push(move)
  next.toPlay = opp
  next.koPoint = koPoint
  next.positionHashes = [...hashes, hash]
  next.consecutivePasses = 0
  return { ok: true, state: next, move }
}

export function pass(state: GameState): PlayResult {
  if (state.ended) return { ok: false, reason: 'game_ended' }
  const next = cloneState(state)
  if (!next.positionHashes?.length) {
    next.positionHashes = [boardHash(next.board)]
  }
  const move: Move = {
    player: state.toPlay,
    x: -1,
    y: -1,
    pass: true,
    captured: [],
  }
  next.history.push(move)
  next.toPlay = opposite(state.toPlay)
  next.koPoint = null
  next.consecutivePasses = state.consecutivePasses + 1
  if (next.consecutivePasses >= 2) next.ended = true
  return { ok: true, state: next, move }
}

export function starPoints(size: BoardSize): Point[] {
  if (size === 9) return [
    { x: 2, y: 2 }, { x: 6, y: 2 }, { x: 4, y: 4 }, { x: 2, y: 6 }, { x: 6, y: 6 },
  ]
  if (size === 13) return [
    { x: 3, y: 3 }, { x: 9, y: 3 }, { x: 6, y: 6 }, { x: 3, y: 9 }, { x: 9, y: 9 },
  ]
  return [
    { x: 3, y: 3 }, { x: 9, y: 3 }, { x: 15, y: 3 },
    { x: 3, y: 9 }, { x: 9, y: 9 }, { x: 15, y: 9 },
    { x: 3, y: 15 }, { x: 9, y: 15 }, { x: 15, y: 15 },
  ]
}

/**
 * 사람이 읽는 좌표 (A1 = 좌하단, 표준 바둑/GTP 표기).
 * board 배열은 y=0 이 위쪽 줄이므로 세로를 뒤집어야 한다.
 * SGF(`sgfCoord`)는 원래 위쪽이 'a' 라서 뒤집지 않는다.
 */
export function pointLabel(x: number, y: number, size: number): string {
  const letters = 'ABCDEFGHJKLMNOPQRST'
  return `${letters[x]}${size - y}`
}
