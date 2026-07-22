import { describe, expect, it } from 'vitest'
import { createGame, pass, tryPlay } from './board'

describe('go engine', () => {
  it('places stones and alternates', () => {
    let g = createGame(9)
    const a = tryPlay(g, 3, 3)
    expect(a.ok).toBe(true)
    if (!a.ok) return
    g = a.state
    expect(g.toPlay).toBe(2)
    const b = tryPlay(g, 4, 3)
    expect(b.ok).toBe(true)
  })

  it('captures a single stone', () => {
    let g = createGame(9)
    // Black surrounds (1,1): north/west/east first, then white enters, black south captures
    const sequence: [number, number][] = [
      [0, 1], // B
      [5, 5], // W dummy
      [1, 0], // B
      [5, 6], // W dummy
      [2, 1], // B
      [1, 1], // W — the victim
      [1, 2], // B — capture
    ]
    let last = tryPlay(g, sequence[0][0], sequence[0][1])
    expect(last.ok).toBe(true)
    if (!last.ok) return
    g = last.state
    for (let i = 1; i < sequence.length; i++) {
      last = tryPlay(g, sequence[i][0], sequence[i][1])
      expect(last.ok).toBe(true)
      if (!last.ok) return
      g = last.state
    }
    expect(last.move.captured).toEqual([{ x: 1, y: 1 }])
    expect(g.captures[1]).toBe(1)
  })

  it('rejects suicide', () => {
    let g = createGame(9)
    // Black surrounds corner (0,0); White must not play there
    const setup: [number, number][] = [
      [1, 0], // B
      [5, 5], // W
      [0, 1], // B
      [5, 6], // W
    ]
    for (const [x, y] of setup) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    // Black to play — pass so White faces suicide at (0,0)
    const p = pass(g)
    expect(p.ok).toBe(true)
    if (!p.ok) return
    g = p.state
    const suicide = tryPlay(g, 0, 0)
    expect(suicide.ok).toBe(false)
  })

  it('ends after two passes', () => {
    let g = createGame(9)
    let r = pass(g)
    if (!r.ok) throw new Error('pass')
    g = r.state
    r = pass(g)
    if (!r.ok) throw new Error('pass')
    expect(r.state.ended).toBe(true)
  })
})
