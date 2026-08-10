// src/router/routes.test.ts
import { describe, expect, it } from 'vitest'
import {
  hashForScreen,
  isEmptyHash,
  isScreen,
  screenFromHash,
  SCREENS,
} from './routes'

describe('해시 라우팅 변환', () => {
  it('모든 화면이 왕복한다', () => {
    for (const s of SCREENS) {
      expect(screenFromHash(hashForScreen(s))).toBe(s)
    }
  })

  it('알 수 없는 해시는 홈으로', () => {
    expect(screenFromHash('#/nope')).toBe('home')
    expect(screenFromHash('#/')).toBe('home')
    expect(screenFromHash('')).toBe('home')
    expect(screenFromHash('#')).toBe('home')
  })

  it('앞의 # 와 / 유무·대소문자를 견딘다', () => {
    expect(screenFromHash('#/solo')).toBe('solo')
    expect(screenFromHash('#solo')).toBe('solo')
    expect(screenFromHash('#/SOLO')).toBe('solo')
    expect(screenFromHash('#/Settings')).toBe('settings')
  })

  it('뒤에 붙은 경로·쿼리를 무시한다', () => {
    expect(screenFromHash('#/learn/basics-1')).toBe('learn')
    expect(screenFromHash('#/solo?size=19')).toBe('solo')
  })

  it('빈 해시를 구분한다 — 스냅샷 자동 복원 판단 기준', () => {
    expect(isEmptyHash('')).toBe(true)
    expect(isEmptyHash('#')).toBe(true)
    expect(isEmptyHash('#/')).toBe(true)
    expect(isEmptyHash('#/settings')).toBe(false)
    // 딥링크가 있으면 자동 복원이 가로채면 안 된다
    expect(isEmptyHash('#/learn')).toBe(false)
  })

  it('isScreen 이 잡값을 거른다', () => {
    expect(isScreen('solo')).toBe(true)
    expect(isScreen('nope')).toBe(false)
    expect(isScreen(null)).toBe(false)
    expect(isScreen(3)).toBe(false)
  })
})
