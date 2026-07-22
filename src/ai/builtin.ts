import { legalMoves, opposite, tryPlay } from '../engine/board'
import type { GameState, Point } from '../engine/types'
import { getRank, type RankId } from './ranks'

function scoreMove(state: GameState, p: Point): number {
  const r = tryPlay(state, p.x, p.y)
  if (!r.ok) return -Infinity
  let score = r.move.captured.length * 50
  const center = (state.size - 1) / 2
  const dist = Math.abs(p.x - center) + Math.abs(p.y - center)
  score += (state.size - dist) * 0.5
  // 약간 테두리 선호 (초급용)
  if (p.x === 0 || p.y === 0 || p.x === state.size - 1 || p.y === state.size - 1) {
    score -= 2
  }
  // 상대 따냄 기회 유지
  const after = r.state
  const replyThreats = legalMoves(after).filter((m) => {
    const rr = tryPlay(after, m.x, m.y)
    return rr.ok && rr.move.captured.length > 0
  }).length
  if (after.toPlay === opposite(state.toPlay) && replyThreats > 2) score -= 3
  return score + Math.random() * 2
}

/** KataGo 없을 때 쓰는 휴리스틱 AI */
export function pickBuiltinMove(state: GameState, rankId: RankId): Point | null {
  const moves = legalMoves(state)
  if (moves.length === 0) return null
  const rank = getRank(rankId)
  if (Math.random() < rank.randomness) {
    return moves[Math.floor(Math.random() * moves.length)]
  }
  let best = moves[0]
  let bestScore = -Infinity
  for (const m of moves) {
    const s = scoreMove(state, m)
    if (s > bestScore) {
      bestScore = s
      best = m
    }
  }
  return best
}
