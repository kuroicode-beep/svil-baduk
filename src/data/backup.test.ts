// src/data/backup.test.ts
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  BACKUP_FORMAT,
  BACKUP_KEYS,
  BACKUP_VERSION,
  backupFilename,
  buildBackup,
  restoreBackup,
} from './backup'

beforeEach(() => {
  const store = new Map<string, string>()
  vi.stubGlobal('localStorage', {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
    clear: () => store.clear(),
  })
})

describe('백업 내보내기', () => {
  it('저장된 키를 모아 버전 있는 파일을 만든다', () => {
    localStorage.setItem('svil-baduk-settings', JSON.stringify({ v: 1, fontSize: 'large' }))
    localStorage.setItem('svil-baduk-profile', JSON.stringify({ name: '인블루', level: 3 }))

    const file = buildBackup('0.9.1')
    expect(file.format).toBe(BACKUP_FORMAT)
    expect(file.version).toBe(BACKUP_VERSION)
    expect(file.appVersion).toBe('0.9.1')
    expect(file.data['svil-baduk-settings']).toEqual({ v: 1, fontSize: 'large' })
    expect(file.data['svil-baduk-profile']).toEqual({ name: '인블루', level: 3 })
  })

  it('진행 중인 대국은 담지 않는다 — 엔진 표현이라 호환을 보장할 수 없다', () => {
    localStorage.setItem('svil-baduk-solo-snapshot', JSON.stringify({ v: 1, state: {} }))
    const file = buildBackup('0.9.1')
    expect(Object.keys(file.data)).not.toContain('svil-baduk-solo-snapshot')
    expect(BACKUP_KEYS).not.toContain('svil-baduk-solo-snapshot' as never)
  })

  it('손상된 값이 있어도 백업 전체가 실패하지 않는다', () => {
    localStorage.setItem('svil-baduk-settings', '{{{ 깨진 JSON')
    localStorage.setItem('svil-baduk-profile', JSON.stringify({ name: 'ok' }))
    const file = buildBackup('0.9.1')
    expect(file.data['svil-baduk-settings']).toBeUndefined()
    expect(file.data['svil-baduk-profile']).toEqual({ name: 'ok' })
  })

  it('없는 키는 조용히 건너뛴다', () => {
    expect(Object.keys(buildBackup('0.9.1').data)).toEqual([])
  })
})

describe('백업 가져오기', () => {
  it('내보낸 것을 그대로 되돌린다', () => {
    localStorage.setItem('svil-baduk-settings', JSON.stringify({ v: 1, fontSize: 'large' }))
    localStorage.setItem('svil-baduk-learn-progress', JSON.stringify({ v: 1, solved: ['b1-center'] }))
    const text = JSON.stringify(buildBackup('0.9.1'))

    localStorage.clear()
    const result = restoreBackup(text)
    expect(result.ok).toBe(true)
    if (!result.ok) return
    expect(result.restored).toEqual(['svil-baduk-settings', 'svil-baduk-learn-progress'])
    expect(JSON.parse(localStorage.getItem('svil-baduk-settings')!)).toEqual({
      v: 1,
      fontSize: 'large',
    })
    expect(JSON.parse(localStorage.getItem('svil-baduk-learn-progress')!).solved).toEqual([
      'b1-center',
    ])
  })

  it('JSON 이 아니면 거부', () => {
    expect(restoreBackup('안녕')).toEqual({ ok: false, reason: 'not_json' })
  })

  it('다른 앱의 JSON 은 거부 — format 을 확인한다', () => {
    expect(restoreBackup(JSON.stringify({ hello: 1 }))).toEqual({ ok: false, reason: 'not_backup' })
    expect(restoreBackup(JSON.stringify({ format: 'other-app', version: 1, data: {} }))).toEqual({
      ok: false,
      reason: 'not_backup',
    })
  })

  it('미래 버전 백업은 거부 — 조용히 망가뜨리지 않는다', () => {
    const future = JSON.stringify({
      format: BACKUP_FORMAT,
      version: BACKUP_VERSION + 1,
      appVersion: '9.9.9',
      savedAt: new Date().toISOString(),
      data: {},
    })
    expect(restoreBackup(future)).toEqual({ ok: false, reason: 'unsupported_version' })
  })

  it('일부 키만 든 백업도 받아들이고 나머지는 건너뛴 것으로 보고한다', () => {
    const partial = JSON.stringify({
      format: BACKUP_FORMAT,
      version: BACKUP_VERSION,
      appVersion: '0.9.1',
      savedAt: new Date().toISOString(),
      data: { 'svil-baduk-profile': { name: '인블루' } },
    })
    const result = restoreBackup(partial)
    expect(result.ok).toBe(true)
    if (!result.ok) return
    expect(result.restored).toEqual(['svil-baduk-profile'])
    expect(result.skipped).toContain('svil-baduk-settings')
  })

  it('한글·유니코드가 왕복해도 깨지지 않는다', () => {
    localStorage.setItem('svil-baduk-profile', JSON.stringify({ name: '인블루 소장님 🏯' }))
    const text = JSON.stringify(buildBackup('0.9.1'))
    localStorage.clear()
    restoreBackup(text)
    expect(JSON.parse(localStorage.getItem('svil-baduk-profile')!).name).toBe('인블루 소장님 🏯')
  })
})

describe('backupFilename', () => {
  it('파일명에 버전과 시각이 들어가고 경로 문자가 없다', () => {
    const name = backupFilename('0.9.1', new Date('2026-08-09T12:34:56Z'))
    expect(name).toBe('svil-baduk-backup-0.9.1-2026-08-09-12-34-56.json')
    expect(name).not.toMatch(/[/\\:]/)
  })
})
