import { idx } from './board'
import type { BoardSize, GameState, Player, Point, Stone } from './types'

export type GoRules = 'japanese' | 'chinese'

export interface ScoreBreakdown {
  blackTerritory: number
  whiteTerritory: number
  blackCaptures: number
  whiteCaptures: number
  blackStones: number
  whiteStones: number
  komi: number
  rules: GoRules
  blackTotal: number
  whiteTotal: number
  /** 1=흑승 2=백승 0=무승부(거의 없음) */
  winner: 0 | Player
  /** 빈 점 소유: 1흑집 2백집 0공배/미확정 */
  ownership: Stone[]
}

/** 일본식: 집+사석+덤 / 중국식: 집+돌수+덤 */
export function komiFor(size: BoardSize, rules: GoRules = 'japanese'): number {
  if (rules === 'chinese') {
    return size === 9 ? 7.5 : 7.5
  }
  if (size === 19) return 6.5
  if (size === 13) return 5.5
  return 5.5
}

function neighbors(size: number, x: number, y: number): Point[] {
  const out: Point[] = []
  if (x > 0) out.push({ x: x - 1, y })
  if (x < size - 1) out.push({ x: x + 1, y })
  if (y > 0) out.push({ x, y: y - 1 })
  if (y < size - 1) out.push({ x, y: y + 1 })
  return out
}

export function estimateScore(
  state: GameState,
  rules: GoRules = 'japanese',
  komiOverride?: number,
): ScoreBreakdown {
  const { size, board } = state
  const ownership = Array<Stone>(size * size).fill(0)
  const visited = new Set<number>()
  let blackTerritory = 0
  let whiteTerritory = 0
  let blackStones = 0
  let whiteStones = 0

  for (let i = 0; i < board.length; i++) {
    if (board[i] === 1) blackStones += 1
    else if (board[i] === 2) whiteStones += 1
  }

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = idx(size, x, y)
      if (board[i] !== 0 || visited.has(i)) continue

      const region: Point[] = []
      const stack: Point[] = [{ x, y }]
      let touchesBlack = false
      let touchesWhite = false

      while (stack.length) {
        const p = stack.pop()!
        const pi = idx(size, p.x, p.y)
        if (visited.has(pi)) continue
        if (board[pi] !== 0) continue
        visited.add(pi)
        region.push(p)
        for (const n of neighbors(size, p.x, p.y)) {
          const ni = idx(size, n.x, n.y)
          const v = board[ni]
          if (v === 1) touchesBlack = true
          else if (v === 2) touchesWhite = true
          else if (!visited.has(ni)) stack.push(n)
        }
      }

      let owner: Stone = 0
      if (touchesBlack && !touchesWhite) owner = 1
      else if (touchesWhite && !touchesBlack) owner = 2

      for (const p of region) {
        ownership[idx(size, p.x, p.y)] = owner
      }
      if (owner === 1) blackTerritory += region.length
      else if (owner === 2) whiteTerritory += region.length
    }
  }

  const blackCaptures = state.captures[1]
  const whiteCaptures = state.captures[2]
  const komi = komiOverride ?? komiFor(state.size, rules)

  let blackTotal: number
  let whiteTotal: number
  if (rules === 'chinese') {
    // 영역법 근사: 집 + 살아 있는 돌 (+ 덤은 백)
    blackTotal = blackTerritory + blackStones
    whiteTotal = whiteTerritory + whiteStones + komi
  } else {
    blackTotal = blackTerritory + blackCaptures
    whiteTotal = whiteTerritory + whiteCaptures + komi
  }

  let winner: 0 | Player = 0
  if (state.resignedBy === 1) winner = 2
  else if (state.resignedBy === 2) winner = 1
  else if (blackTotal > whiteTotal) winner = 1
  else if (whiteTotal > blackTotal) winner = 2

  return {
    blackTerritory,
    whiteTerritory,
    blackCaptures,
    whiteCaptures,
    blackStones,
    whiteStones,
    komi,
    rules,
    blackTotal,
    whiteTotal,
    winner,
    ownership,
  }
}

export function formatScoreSummary(
  score: ScoreBreakdown,
  labels: { black: string; white: string; draw: string },
): string {
  const result =
    score.winner === 1
      ? `${labels.black} 승`
      : score.winner === 2
        ? `${labels.white} 승`
        : labels.draw
  return `${result} · ${labels.black} ${score.blackTotal} / ${labels.white} ${score.whiteTotal} (덤 ${score.komi})`
}
