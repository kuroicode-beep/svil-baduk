import { describe, expect, it } from 'vitest'
import { lessonsFor, puzzlesFor } from './localize'

describe('learn localize', () => {
  it('keeps Korean as default source', () => {
    expect(lessonsFor('ko')[0].title).toContain('바둑판')
    expect(puzzlesFor('ko')[0].title).toContain('따냄')
  })

  it('switches titles for other languages', () => {
    expect(lessonsFor('en')[0].title).toMatch(/Board/i)
    expect(lessonsFor('ja')[0].title).toContain('盤')
    expect(lessonsFor('zh')[0].title).toContain('棋盘')
    expect(lessonsFor('vi')[0].title).toMatch(/Bàn/i)
    expect(puzzlesFor('en')[0].goalLabel).toMatch(/Goal/i)
    expect(puzzlesFor('ja')[0].setup).toEqual(puzzlesFor('ko')[0].setup)
  })
})
