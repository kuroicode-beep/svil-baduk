import { describe, expect, it } from 'vitest'
import { createGame, tryPlay, pass } from '../engine/board'
import { decodeSgf, encodeSgf, replayTo } from './sgf'

describe('sgf', () => {
  it('round-trips a short game', () => {
    let g = createGame(9)
    let r = tryPlay(g, 2, 2)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    g = r.state
    r = tryPlay(g, 6, 6)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    g = r.state
    r = pass(g)
    if (!r.ok) return
    g = r.state
    r = pass(g)
    if (!r.ok) return
    g = r.state

    const text = encodeSgf(g, { black: 'Human', white: 'AI' })
    expect(text).toContain('SZ[9]')
    expect(text).toContain('PB[Human]')
    const loaded = decodeSgf(text)
    expect(loaded.ok).toBe(true)
    if (!loaded.ok) return
    expect(loaded.state.history.length).toBe(g.history.length)
    expect(loaded.state.ended).toBe(true)
  })

  it('replays to ply', () => {
    let g = createGame(9)
    for (const [x, y] of [
      [3, 3],
      [4, 4],
      [3, 4],
    ] as const) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    const mid = replayTo(g.history, 9, 1)
    expect(mid.history.length).toBe(1)
    expect(mid.toPlay).toBe(2)
  })
})
