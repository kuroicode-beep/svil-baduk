import { describe, expect, it } from 'vitest'
import { parseGenmoveToken } from './gtpParse'

describe('parseGenmoveToken', () => {
  it('parses coordinates', () => {
    expect(parseGenmoveToken('= D4')).toEqual({ x: 3, y: 3 })
    expect(parseGenmoveToken('Q16')).toEqual({ x: 15, y: 15 })
  })

  it('maps pass/resign', () => {
    expect(parseGenmoveToken('= pass')).toBe('pass')
    expect(parseGenmoveToken('resign')).toBe('pass')
  })

  it('rejects junk', () => {
    expect(parseGenmoveToken('=')).toBeNull()
    expect(parseGenmoveToken('= @1')).toBeNull()
  })
})
