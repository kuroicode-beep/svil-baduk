import { describe, expect, it } from 'vitest'
import { createGame, idx, pass, resign, tryPlay } from './board'
import { estimateScore, komiFor } from './scoring'
describe('beginner scoring', () => {
  it('assigns corner territory to surrounding color', () => {
    const g = createGame(9)
    // Black wall sealing left-top empty 2x2-ish
    g.board[idx(9, 2, 0)] = 1
    g.board[idx(9, 2, 1)] = 1
    g.board[idx(9, 0, 2)] = 1
    g.board[idx(9, 1, 2)] = 1
    g.board[idx(9, 2, 2)] = 1
    const s = estimateScore(g)
    expect(s.blackTerritory).toBeGreaterThan(0)
    expect(s.ownership[idx(9, 0, 0)]).toBe(1)
    expect(s.ownership[idx(9, 1, 1)]).toBe(1)
  })

  it('treats dame touching both as neutral', () => {
    const g = createGame(9)
    g.board[idx(9, 3, 4)] = 1
    g.board[idx(9, 5, 4)] = 2
    // empty (4,4) touches B and W
    const s = estimateScore(g)
    expect(s.ownership[idx(9, 4, 4)]).toBe(0)
  })

  it('includes captures and komi in totals', () => {
    let g = createGame(9)
    // Capture setup from board tests
    const sequence: [number, number][] = [
      [0, 1],
      [5, 5],
      [1, 0],
      [5, 6],
      [2, 1],
      [1, 1],
      [1, 2],
    ]
    for (const [x, y] of sequence) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    let r = pass(g)
    if (!r.ok) return
    g = r.state
    r = pass(g)
    if (!r.ok) return
    g = r.state
    expect(g.ended).toBe(true)
    const s = estimateScore(g)
    expect(s.blackCaptures).toBe(1)
    expect(s.komi).toBe(komiFor(9, 'japanese'))
    expect(s.whiteTotal).toBe(s.whiteTerritory + s.whiteCaptures + s.komi)
  })

  it('chinese rules use stones + territory + komi', () => {
    const g = createGame(9)
    g.board[idx(9, 0, 0)] = 1
    g.board[idx(9, 8, 8)] = 2
    const jp = estimateScore(g, 'japanese')
    const cn = estimateScore(g, 'chinese')
    expect(cn.rules).toBe('chinese')
    expect(cn.komi).toBe(7.5)
    expect(cn.blackTotal).toBe(cn.blackTerritory + cn.blackStones)
    expect(cn.whiteTotal).toBe(cn.whiteTerritory + cn.whiteStones + cn.komi)
    expect(cn.blackStones).toBeGreaterThanOrEqual(jp.blackCaptures >= 0 ? 1 : 0)
  })

  it('awards win to opponent on resign', () => {
    const g = resign(createGame(9), 1)
    const s = estimateScore(g)
    expect(s.winner).toBe(2)
  })
})
