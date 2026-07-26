// src/ai/builtin.test.ts — 내장 AI 휴리스틱 검증
import { describe, expect, it } from 'vitest'
import { createGame, idx, tryPlay } from '../engine/board'
import type { GameState, Player, Stone } from '../engine/types'
import { pickBuiltinMove, pickBuiltinTopMoves } from './builtin'

function setup(size: 9 | 13 | 19, rows: string[], toPlay: Player): GameState {
  const g = createGame(size)
  g.toPlay = toPlay
  for (let y = 0; y < size; y++) {
    const row = rows[y] ?? ''
    for (let x = 0; x < size; x++) {
      const ch = row[x] ?? '.'
      let stone: Stone = 0
      if (ch === 'B') stone = 1
      else if (ch === 'W') stone = 2
      g.board[idx(size, x, y)] = stone
    }
  }
  return g
}

describe('pickBuiltinTopMoves', () => {
  it('returns labeled top moves', () => {
    let g = createGame(9)
    const r = tryPlay(g, 4, 4)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    g = r.state
    const top = pickBuiltinTopMoves(g, 3)
    expect(top.length).toBeGreaterThan(0)
    expect(top[0].label.startsWith('1·')).toBe(true)
  })

  it('prefers an immediate capture', () => {
    // 백(2,7)이 단수 — (2,7) 오른쪽 활로 (2,7)?? 흑이 (2,7)에 두면 따냄
    const g = setup(
      9,
      [
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
      1,
    )
    const top = pickBuiltinTopMoves(g, 1)
    expect(top[0].point).toEqual({ x: 2, y: 7 })
  })

  it('rescues own group in atari', () => {
    // 흑(2,4)가 단수(활로 (3,4) 하나) — 최고 수는 뻗기 (3,4)
    const g = setup(
      9,
      [
        '.........',
        '.........',
        '.........',
        '..W......',
        '.WB......',
        '..W......',
        '.........',
        '.........',
        '.........',
      ],
      1,
    )
    const top = pickBuiltinTopMoves(g, 1)
    expect(top[0].point).toEqual({ x: 3, y: 4 })
  })

  it('never fills its own true eye', () => {
    // 흑 그룹의 진짜 눈 (3,3) — 후보에서 제외되어야 함
    const g = setup(
      9,
      [
        '.........',
        '.........',
        '..BBB....',
        '..B.B....',
        '..BBB....',
        '.........',
        '.........',
        '.........',
        '.........',
      ],
      1,
    )
    const top = pickBuiltinTopMoves(g, 81)
    expect(top.some((m) => m.point.x === 3 && m.point.y === 3)).toBe(false)
  })
})

describe('pickBuiltinMove', () => {
  it('passes back when opponent passed and nothing useful remains', () => {
    // 판이 정리된 상태 + 상대 패스 → 낮은 평가면 패스(null)
    const g = setup(
      9,
      [
        'BBBBWWWWW',
        'BBBBWWWWW',
        'BBBBWWWWW',
        'BBBBWWWWW',
        'BBBBWWWWW',
        'BBBBWWWWW',
        'BBB.WWWWW',
        'BBBBWWWWW',
        '.BBBWWWW.',
      ],
      1,
    )
    g.consecutivePasses = 1
    // lv10: 랜덤 없이 평가 기반 선택
    const m = pickBuiltinMove(g, 'lv10')
    expect(m).toBeNull()
  })

  it('returns a legal move in normal positions', () => {
    const g = createGame(9)
    const m = pickBuiltinMove(g, 'lv5')
    expect(m).not.toBeNull()
    if (m) expect(tryPlay(g, m.x, m.y).ok).toBe(true)
  })
})
