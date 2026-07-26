// src/ai/builtin.ts — KataGo 없을 때 쓰는 내장 휴리스틱 AI
import { groupAndLibs, idx, inBounds, legalMoves, tryPlay } from '../engine/board'
import type { GameState, Point, Stone } from '../engine/types'
import { getRank, type RankId } from './ranks'

export interface RankedMove {
  point: Point
  score: number
  label: string
}

/** 이 점이 color의 '진짜 눈'인지 — 상하좌우 전부 아군, 대각 적 점유가 기준 미만 */
function isTrueEye(board: Stone[], size: number, x: number, y: number, color: Stone): boolean {
  if (board[idx(size, x, y)] !== 0) return false
  const orth: Array<[number, number]> = [
    [x - 1, y],
    [x + 1, y],
    [x, y - 1],
    [x, y + 1],
  ]
  for (const [nx, ny] of orth) {
    if (!inBounds(size, nx, ny)) continue
    if (board[idx(size, nx, ny)] !== color) return false
  }
  const diag: Array<[number, number]> = [
    [x - 1, y - 1],
    [x + 1, y - 1],
    [x - 1, y + 1],
    [x + 1, y + 1],
  ]
  let enemyDiag = 0
  let offBoard = 0
  for (const [nx, ny] of diag) {
    if (!inBounds(size, nx, ny)) {
      offBoard += 1
      continue
    }
    const v = board[idx(size, nx, ny)]
    if (v !== 0 && v !== color) enemyDiag += 1
  }
  // 변·귀는 대각 1개만 적이어도 가짜 눈, 중앙은 2개부터
  const limit = offBoard > 0 ? 1 : 2
  return enemyDiag < limit
}

/**
 * 한 수 평가 (합법수 전수 재탐색 없이 가벼운 지표만):
 * 따냄 / 단수 걸기 / 단수 도망 / 자충 회피 / 초반 3·4선 선호
 */
function evaluateMove(state: GameState, p: Point, noise: number): number {
  const { size, board, toPlay } = state
  const opp: Stone = toPlay === 1 ? 2 : 1

  // 자기 진짜 눈 메우기는 절대 금지 (종반 자멸 방지)
  if (isTrueEye(board, size, p.x, p.y, toPlay)) return -Infinity

  const r = tryPlay(state, p.x, p.y)
  if (!r.ok) return -Infinity

  let score = r.move.captured.length * 40

  const after = r.state.board

  // 착수 후 내 그룹 활로 — 자충(스스로 단수) 강한 감점
  const own = groupAndLibs(after, size, p.x, p.y)
  if (own.libs.length === 1) score -= 30
  else if (own.libs.length === 2) score -= 4

  // 착수 전 인접 아군이 단수였는데 이 수로 살아나면 큰 가점 (단수 도망/이음)
  const orth: Array<[number, number]> = [
    [p.x - 1, p.y],
    [p.x + 1, p.y],
    [p.x, p.y - 1],
    [p.x, p.y + 1],
  ]
  let rescued = false
  const seenOppGroup = new Set<number>()
  let atariThreats = 0
  let pressure = 0
  let ownContact = 0
  for (const [nx, ny] of orth) {
    if (!inBounds(size, nx, ny)) continue
    const before = board[idx(size, nx, ny)]
    if (before === toPlay) {
      ownContact += 1
      if (!rescued) {
        const g = groupAndLibs(board, size, nx, ny)
        if (g.libs.length === 1 && own.libs.length >= 2) rescued = true
      }
    } else if (before === opp) {
      const rootAfter = after[idx(size, nx, ny)]
      if (rootAfter !== opp) continue // 이미 따낸 돌
      const key = idx(size, nx, ny)
      if (seenOppGroup.has(key)) continue
      const g = groupAndLibs(after, size, nx, ny)
      for (const s of g.stones) seenOppGroup.add(idx(size, s.x, s.y))
      if (g.libs.length === 1) atariThreats += 1
      else if (g.libs.length === 2) pressure += 1
    }
  }
  if (rescued) score += 34
  score += atariThreats * 14 + pressure * 4 + ownContact * 1

  // 초반 위치 감각: 3·4선(귀·변) 선호, 1·2선·과한 중앙 지양
  const early = state.history.length < size * 2
  const line = Math.min(p.x, p.y, size - 1 - p.x, size - 1 - p.y) + 1
  if (early) {
    if (line === 3 || line === 4) score += 6
    else if (line === 2) score += 1
    else if (line === 1) score -= 5
    else score += 2
  } else {
    const center = (size - 1) / 2
    const dist = Math.abs(p.x - center) + Math.abs(p.y - center)
    score += (size - dist) * 0.3
    if (line === 1) score -= 2
  }

  return score + (noise > 0 ? Math.random() * noise : 0)
}

/** 후보 목록 — 자기 눈 메우기 제외 */
function candidateMoves(state: GameState): Point[] {
  return legalMoves(state).filter(
    (p) => !isTrueEye(state.board, state.size, p.x, p.y, state.toPlay),
  )
}

/**
 * 내장 AI 착수 선택. null = 패스 권고.
 * - 의미 있는 수가 없고 상대가 패스했으면 패스해 대국을 끝냄
 */
export function pickBuiltinMove(state: GameState, rankId: RankId): Point | null {
  const moves = candidateMoves(state)
  if (moves.length === 0) return null

  const rank = getRank(rankId)
  // 레벨이 낮을수록 평가에 노이즈를 더해 실수 유도
  const noise = Math.max(0, (10 - rank.level) * 1.2)
  let best: Point | null = null
  let bestScore = -Infinity
  for (const m of moves) {
    const s = evaluateMove(state, m, noise)
    if (s > bestScore) {
      bestScore = s
      best = m
    }
  }
  if (best === null) return null

  // 상대가 패스했고 따냄·구출 같은 급한 수가 없으면 레벨 무관 같이 패스 (계가로 종료)
  if (state.consecutivePasses >= 1 && bestScore < 10) return null

  if (Math.random() < rank.randomness) {
    return moves[Math.floor(Math.random() * moves.length)]
  }
  return best
}

/** 힌트/분석: 상위 n수 + 숫자 라벨 (랜덤 없음) */
export function pickBuiltinTopMoves(state: GameState, n = 3): RankedMove[] {
  const moves = candidateMoves(state)
  if (moves.length === 0) return []
  const ranked = moves
    .map((point) => ({ point, score: evaluateMove(state, point, 0) }))
    .filter((m) => Number.isFinite(m.score))
    .sort((a, b) => b.score - a.score)
    .slice(0, Math.max(1, n))
  const best = ranked[0]?.score || 1
  return ranked.map((m, i) => {
    const pct = Math.max(1, Math.round((m.score / Math.max(best, 1)) * 100))
    return {
      point: m.point,
      score: m.score,
      label: `${i + 1}·${pct}`,
    }
  })
}
