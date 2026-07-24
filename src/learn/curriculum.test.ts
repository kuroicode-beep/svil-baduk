import { describe, expect, it } from 'vitest'
import { tryPlay } from '../engine/board'
import { problemState } from './boardSetup'
import { STAGES, stagesForTrack } from './curriculum'
import { isStageCleared, isStageUnlocked } from './progress'

describe('learn curriculum', () => {
  it('has three tracks with ordered stages', () => {
    expect(stagesForTrack('basics').map((s) => s.order)).toEqual([1, 2, 3])
    expect(stagesForTrack('fuseki').map((s) => s.order)).toEqual([1, 2, 3])
    expect(stagesForTrack('tsumego').map((s) => s.order)).toEqual([1, 2, 3])
  })

  it('every problem has unique id and at least one legal solution', () => {
    const ids = new Set<string>()
    for (const stage of STAGES) {
      expect(stage.problems.length).toBeGreaterThan(0)
      for (const p of stage.problems) {
        expect(ids.has(p.id), `duplicate ${p.id}`).toBe(false)
        ids.add(p.id)
        expect(p.solutions.length).toBeGreaterThan(0)
        const before = problemState(p)
        for (const sol of p.solutions) {
          const r = tryPlay(before, sol.x, sol.y)
          expect(r.ok, `${p.id} @${sol.x},${sol.y} illegal`).toBe(true)
          if (!r.ok) continue
          if (p.goal === 'capture') {
            expect(r.move.captured.length, `${p.id} should capture`).toBeGreaterThan(0)
          }
        }
      }
    }
  })

  it('unlocks stages in order within a track', () => {
    const first = stagesForTrack('basics')[0]
    const second = stagesForTrack('basics')[1]
    expect(isStageUnlocked(first.id, [])).toBe(true)
    expect(isStageUnlocked(second.id, [])).toBe(false)
    const solved = first.problems.map((p) => p.id)
    expect(isStageCleared(first.id, solved)).toBe(true)
    expect(isStageUnlocked(second.id, solved)).toBe(true)
  })
})
