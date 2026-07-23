import { describe, expect, it } from 'vitest'
import { tryPlay } from '../engine/board'
import { PUZZLES, puzzleState } from './puzzles'

describe('learn puzzles', () => {
  it('every puzzle solution captures when required', () => {
    for (const p of PUZZLES) {
      const before = puzzleState(p)
      const whiteBefore = before.board.filter((s) => s === 2).length
      expect(p.solutions.length).toBeGreaterThan(0)
      for (const sol of p.solutions) {
        const r = tryPlay(before, sol.x, sol.y)
        expect(r.ok, `${p.id} @${sol.x},${sol.y}`).toBe(true)
        if (!r.ok) return
        if (p.goal === 'capture') {
          expect(r.move.captured.length, p.id).toBeGreaterThan(0)
          const whiteAfter = r.state.board.filter((s) => s === 2).length
          expect(whiteAfter).toBeLessThan(whiteBefore)
        }
      }
    }
  })
})
