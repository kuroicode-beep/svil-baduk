import { createGame, idx } from '../engine/board'
import type { BoardSize, GameState, Player, Point, Stone } from '../engine/types'

export type PuzzleGoal = 'capture'

export interface Puzzle {
  id: string
  title: string
  goalLabel: string
  goal: PuzzleGoal
  size: BoardSize
  toPlay: Player
  /** row strings: B/W/.  length = size */
  setup: string[]
  solutions: Point[]
  hint: string
}

function parseSetup(size: BoardSize, rows: string[], toPlay: Player): GameState {
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

export function puzzleState(p: Puzzle): GameState {
  return parseSetup(p.size, p.setup, p.toPlay)
}

export const PUZZLES: Puzzle[] = [
  {
    id: 'cap-corner',
    title: '따냄 1 — 귀 근처 한 점',
    goalLabel: '목표: 백 돌 따내기',
    goal: 'capture',
    size: 9,
    toPlay: 1,
    setup: [
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.B.......',
      'BW.......',
      '.B.......',
    ],
    solutions: [{ x: 2, y: 7 }],
    hint: '백의 남은 활로(오른쪽)를 막으세요.',
  },
  {
    id: 'cap-side',
    title: '따냄 2 — 변의 한 점',
    goalLabel: '목표: 백 돌 따내기',
    goal: 'capture',
    size: 9,
    toPlay: 1,
    setup: [
      '.........',
      '.........',
      '.........',
      '..B.B....',
      '..BWB....',
      '...B.....',
      '.........',
      '.........',
      '.........',
    ],
    solutions: [{ x: 3, y: 3 }],
    hint: '백 위쪽 빈 교차점이 마지막 활로입니다.',
  },
  {
    id: 'cap-two',
    title: '따냄 3 — 두 점',
    goalLabel: '목표: 백 두 점 따내기',
    goal: 'capture',
    size: 9,
    toPlay: 1,
    setup: [
      '.........',
      '.........',
      '.........',
      '..BBB....',
      '.BWWB....',
      '..B.B....',
      '...B.....',
      '.........',
      '.........',
    ],
    solutions: [{ x: 3, y: 5 }],
    hint: '백 덩어리의 빈 칸을 메우세요.',
  },
  {
    id: 'atari',
    title: '따냄 4 — 단수',
    goalLabel: '목표: 단수인 백 따내기',
    goal: 'capture',
    size: 9,
    toPlay: 1,
    setup: [
      '.........',
      '.........',
      '..BBB....',
      '.BW.B....',
      '..BBB....',
      '.........',
      '.........',
      '.........',
      '.........',
    ],
    solutions: [{ x: 3, y: 3 }],
    hint: '백은 활로가 하나뿐입니다. 그곳을 두세요.',
  },
  {
    id: 'cap-edge',
    title: '따냄 5 — 변에서 잡기',
    goalLabel: '목표: 백 돌 따내기',
    goal: 'capture',
    size: 9,
    toPlay: 1,
    setup: [
      '.........',
      '.........',
      '.........',
      '.........',
      'BBB......',
      'BWB......',
      'B.B......',
      '.........',
      '.........',
    ],
    solutions: [{ x: 1, y: 6 }],
    hint: '백의 아래 활로를 막으세요.',
  },
]
