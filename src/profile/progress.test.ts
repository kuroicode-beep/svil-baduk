import { describe, expect, it } from 'vitest'
import { applyXp, recordSoloResult, xpForResult, xpToNextLevel } from './progress'
import { defaultProfile } from './store'

describe('profile progress', () => {
  it('xpToNextLevel grows with level', () => {
    expect(xpToNextLevel(1)).toBeLessThan(xpToNextLevel(5))
  })

  it('levels up when XP overflows', () => {
    const p = { ...defaultProfile(), level: 1, xp: xpToNextLevel(1) - 1 }
    const r = applyXp(p, 2)
    expect(r.leveledUp).toBe(1)
    expect(r.profile.level).toBe(2)
  })

  it('win grants more XP than loss', () => {
    expect(xpForResult({ won: true, draw: false, rankId: 'lv5' })).toBeGreaterThan(
      xpForResult({ won: false, draw: false, rankId: 'lv5' }),
    )
  })

  it('records win, high score, best AI', () => {
    const p = { ...defaultProfile(), name: 'Tester', createdAt: '2026-01-01' }
    const r = recordSoloResult(p, {
      myColor: 1,
      winner: 1,
      myScore: 42,
      rankId: 'lv4',
    })
    expect(r.profile.wins).toBe(1)
    expect(r.profile.gamesPlayed).toBe(1)
    expect(r.profile.highScore).toBe(42)
    expect(r.profile.bestAiLevel).toBe(4)
    expect(r.newHighScore).toBe(true)
    expect(r.xpGained).toBeGreaterThan(0)
  })
})
