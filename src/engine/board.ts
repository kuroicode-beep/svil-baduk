import type { BoardSize, GameState, Move, PlayResult, Player, Point, Stone } from './types'

export function idx(size: number, x: number, y: number): number {
  return y * size + x
}

export function inBounds(size: number, x: number, y: number): boolean {
  return x >= 0 && y >= 0 && x < size && y < size
}

export function createGame(size: BoardSize = 19): GameState {
  return {
    size,
    board: Array<Stone>(size * size).fill(0),
    toPlay: 1,
    captures: { 1: 0, 2: 0 },
    history: [],
    koPoint: null,
    consecutivePasses: 0,
    ended: false,
  }
}

export function cloneState(state: GameState): GameState {
  return {
    ...state,
    board: state.board.slice(),
    captures: { ...state.captures },
    history: state.history.slice(),
    koPoint: state.koPoint ? { ...state.koPoint } : null,
  }
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
  next.consecutivePasses = 0
  return { ok: true, state: next, move }
}

export function pass(state: GameState): PlayResult {
  if (state.ended) return { ok: false, reason: 'game_ended' }
  const next = cloneState(state)
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

export function pointLabel(x: number, y: number): string {
  const letters = 'ABCDEFGHJKLMNOPQRST'
  return `${letters[x]}${y + 1}`
}
