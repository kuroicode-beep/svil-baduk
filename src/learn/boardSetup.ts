import { createGame, idx } from '../engine/board'
import type { BoardSize, GameState, Player, Stone } from '../engine/types'
import type { LearnProblem } from './types'

export function parseSetup(size: BoardSize, rows: string[], toPlay: Player): GameState {
  const g = createGame(size)
  g.toPlay = toPlay
  for (let y = 0; y < size; y++) {
    const row = rows[y] ?? ''
    for (let x = 0; x < size; x++) {
      const ch = row[x] ?? '.'
      let stone: Stone = 0
      if (ch === 'B' || ch === 'X') stone = 1
      else if (ch === 'W' || ch === 'O') stone = 2
      g.board[idx(size, x, y)] = stone
    }
  }
  return g
}

export function problemState(p: LearnProblem): GameState {
  return parseSetup(p.size, p.setup, p.toPlay)
}

/** 빈 n줄판 */
export function emptyRows(size: BoardSize): string[] {
  return Array.from({ length: size }, () => '.'.repeat(size))
}
