// src/ai/selfplay.test.ts — 내장 AI 자가대국이 유한 수 안에 정상 종국하는지 (자멸·무한대국 회귀 방지)
import { describe, expect, it } from 'vitest'
import { createGame, pass, tryPlay } from '../engine/board'
import { estimateScore } from '../engine/scoring'
import { pickBuiltinMove } from './builtin'

describe('builtin selfplay smoke', () => {
  it('9x9 selfplay ends by double pass within 300 moves', () => {
    let g = createGame(9)
    let moves = 0
    while (!g.ended && moves < 300) {
      const m = pickBuiltinMove(g, g.toPlay === 1 ? 'lv4' : 'lv8')
      if (m === null) {
        const r = pass(g)
        if (r.ok) g = r.state
      } else {
        const r = tryPlay(g, m.x, m.y)
        if (r.ok) g = r.state
        else {
          const p = pass(g)
          if (p.ok) g = p.state
        }
      }
      moves += 1
    }
    expect(g.ended).toBe(true)
    const score = estimateScore(g)
    expect(score.blackTotal + score.whiteTotal).toBeGreaterThan(0)
  })
})
