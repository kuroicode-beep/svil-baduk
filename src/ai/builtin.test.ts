import { describe, expect, it } from 'vitest'
import { createGame, tryPlay } from '../engine/board'
import { pickBuiltinTopMoves } from './builtin'

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
})
