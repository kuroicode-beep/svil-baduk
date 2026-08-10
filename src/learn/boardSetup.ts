// src/learn/boardSetup.ts — 배우기 문제의 ASCII 배치를 GameState로
import { boardHash, createGame, idx } from '../engine/board'
import type { BoardSize, GameState, Player, Stone } from '../engine/types'
import type { LearnProblem } from './types'

/**
 * ASCII 행 배열을 초기 배치로 가진 상태를 만든다.
 *
 * 돌은 "놓는" 게 아니라 "설치"하는 것이므로 따냄·자살수 검사·차례 전환이 없다.
 * 대신 `positionHashes`를 배치 완료 후 다시 시딩해야 한다 — `createGame`이
 * 빈 판 해시로 채워둔 채 board만 바꾸면 슈퍼코 판정이 틀어진다.
 */
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
  g.positionHashes = [boardHash(g.board)]
  return g
}

export function problemState(p: LearnProblem): GameState {
  return parseSetup(p.size, p.setup, p.toPlay)
}

/** 빈 n줄판 */
export function emptyRows(size: BoardSize): string[] {
  return Array.from({ length: size }, () => '.'.repeat(size))
}
