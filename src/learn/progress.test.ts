import { beforeEach, describe, expect, it, vi } from 'vitest'
import { STAGES } from './curriculum'
import {
  defaultProgress,
  isStageCleared,
  loadLearnProgress,
  markSolved,
  saveLearnProgress,
} from './progress'

function mockLocalStorage() {
  const map = new Map<string, string>()
  vi.stubGlobal('localStorage', {
    getItem: (k: string) => map.get(k) ?? null,
    setItem: (k: string, v: string) => {
      map.set(k, v)
    },
    removeItem: (k: string) => {
      map.delete(k)
    },
    clear: () => map.clear(),
  })
}

describe('learn progress', () => {
  beforeEach(() => {
    mockLocalStorage()
  })

  it('persists solved ids', () => {
    const id = STAGES[0].problems[0].id
    markSolved(id)
    const loaded = loadLearnProgress()
    expect(loaded.solved).toContain(id)
  })

  it('stage clear requires all problems', () => {
    const stage = STAGES[0]
    expect(isStageCleared(stage.id, [])).toBe(false)
    expect(isStageCleared(stage.id, stage.problems.map((p) => p.id))).toBe(true)
  })

  it('save/load roundtrip', () => {
    const p = defaultProgress()
    p.solved = ['x']
    p.lastTrack = 'tsumego'
    saveLearnProgress(p)
    expect(loadLearnProgress().lastTrack).toBe('tsumego')
    expect(loadLearnProgress().solved).toEqual(['x'])
  })
})
