// src/settings/store.test.ts
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  defaultSettings,
  loadSettings,
  migrateSettings,
  resetSettings,
  resolveReduceMotion,
  saveSettings,
  SETTINGS_VERSION,
} from './store'

const KEY = 'svil-baduk-settings'

beforeEach(() => {
  const store = new Map<string, string>()
  vi.stubGlobal('localStorage', {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
    clear: () => store.clear(),
  })
  vi.stubGlobal('window', { matchMedia: undefined })
})

describe('설정 저장 스키마', () => {
  it('저장할 때 버전을 붙인다', () => {
    saveSettings(defaultSettings())
    expect(JSON.parse(localStorage.getItem(KEY)!).v).toBe(SETTINGS_VERSION)
  })

  it('왕복해도 값이 보존된다', () => {
    const s = { ...defaultSettings(), fontSize: 'large' as const, goRules: 'chinese' as const }
    saveSettings(s)
    const loaded = loadSettings()
    expect(loaded.fontSize).toBe('large')
    expect(loaded.goRules).toBe('chinese')
  })

  it('v0(버전 필드 없음): 켜둔 reduceMotion 은 유지한다', () => {
    expect(migrateSettings({ reduceMotion: true }).reduceMotion).toBe(true)
  })

  it("v0: 꺼둔(기본값) reduceMotion 은 'system' 으로 올린다", () => {
    // 한 번만 시딩하면 나중에 OS 에서 켠 사용자에게 반영되지 않는다
    expect(migrateSettings({ reduceMotion: false }).reduceMotion).toBe('system')
    expect(migrateSettings({}).reduceMotion).toBe('system')
  })

  it('v1 저장값의 명시적 false 는 존중한다', () => {
    expect(migrateSettings({ v: 1, reduceMotion: false }).reduceMotion).toBe(false)
  })

  it('손상된 값은 기본값으로 되돌린다', () => {
    const m = migrateSettings({
      v: 1,
      fontSize: 'huge',
      font: 'nonexistent',
      boardScale: 42,
      lineWeight: null,
      reduceMotion: 'weird',
    })
    const d = defaultSettings()
    expect(m.fontSize).toBe(d.fontSize)
    expect(m.font).toBe(d.font)
    expect(m.boardScale).toBe(d.boardScale)
    expect(m.lineWeight).toBe(d.lineWeight)
    expect(m.reduceMotion).toBe(d.reduceMotion)
  })

  it('모르는 키가 있어도 죽지 않는다', () => {
    expect(() => migrateSettings({ v: 1, futureFlag: true })).not.toThrow()
  })

  it('초기화는 기본값을 저장하고 돌려준다', () => {
    saveSettings({ ...defaultSettings(), fontSize: 'large' })
    expect(resetSettings().fontSize).toBe(defaultSettings().fontSize)
    expect(loadSettings().fontSize).toBe(defaultSettings().fontSize)
  })
})

describe('resolveReduceMotion', () => {
  it('명시값은 그대로 쓴다', () => {
    expect(resolveReduceMotion(true)).toBe(true)
    expect(resolveReduceMotion(false)).toBe(false)
  })

  it("'system' 은 OS 선호를 읽는다", () => {
    vi.stubGlobal('window', {
      matchMedia: (q: string) => ({ matches: q.includes('reduced-motion') }),
    })
    expect(resolveReduceMotion('system')).toBe(true)

    vi.stubGlobal('window', { matchMedia: () => ({ matches: false }) })
    expect(resolveReduceMotion('system')).toBe(false)
  })

  it('matchMedia 가 없는 환경에서도 안전하다', () => {
    vi.stubGlobal('window', {})
    expect(resolveReduceMotion('system')).toBe(false)
  })
})
