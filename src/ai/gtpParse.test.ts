import { describe, expect, it } from 'vitest'
import { pointLabel } from '../engine/board'
import { parseGenmoveToken } from './gtpParse'

describe('parseGenmoveToken', () => {
  it('parses coordinates with row 1 at the bottom', () => {
    // D4 = 4번째 줄(아래에서) → board 배열 y = 19 - 4 = 15
    expect(parseGenmoveToken('= D4', 19)).toEqual({ x: 3, y: 15 })
    expect(parseGenmoveToken('Q16', 19)).toEqual({ x: 15, y: 3 })
    expect(parseGenmoveToken('= E5', 9)).toEqual({ x: 4, y: 4 })
  })

  it('round-trips with pointLabel', () => {
    for (const size of [9, 13, 19]) {
      for (const p of [
        { x: 0, y: 0 },
        { x: 3, y: 3 },
        { x: size - 1, y: size - 1 },
        { x: 2, y: size - 3 },
      ]) {
        expect(parseGenmoveToken(pointLabel(p.x, p.y, size), size)).toEqual(p)
      }
    }
  })

  it('maps pass/resign', () => {
    expect(parseGenmoveToken('= pass', 19)).toBe('pass')
    expect(parseGenmoveToken('resign', 19)).toBe('pass')
  })

  it('rejects junk and out-of-range', () => {
    expect(parseGenmoveToken('=', 19)).toBeNull()
    expect(parseGenmoveToken('= @1', 19)).toBeNull()
    expect(parseGenmoveToken('= D20', 19)).toBeNull()
    expect(parseGenmoveToken('= D0', 19)).toBeNull()
    expect(parseGenmoveToken('= K5', 9)).toBeNull()
  })
})
