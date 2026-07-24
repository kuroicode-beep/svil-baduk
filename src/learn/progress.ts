import type { TrackId } from './types'
import { STAGES } from './curriculum'

const KEY = 'svil-baduk-learn-progress'

export type LearnProgress = {
  v: 1
  /** 클리어한 문제 id */
  solved: string[]
  /** 마지막으로 본 트랙/스테이지/문제 */
  lastTrack: TrackId
  lastStageId: string
  lastProblemId: string
}

export function defaultProgress(): LearnProgress {
  const first = STAGES[0]
  return {
    v: 1,
    solved: [],
    lastTrack: first.track,
    lastStageId: first.id,
    lastProblemId: first.problems[0]?.id ?? '',
  }
}

export function loadLearnProgress(): LearnProgress {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return defaultProgress()
    const data = JSON.parse(raw) as LearnProgress
    if (data?.v !== 1 || !Array.isArray(data.solved)) return defaultProgress()
    return { ...defaultProgress(), ...data, solved: [...new Set(data.solved)] }
  } catch {
    return defaultProgress()
  }
}

export function saveLearnProgress(p: LearnProgress) {
  localStorage.setItem(KEY, JSON.stringify(p))
}

export function markSolved(problemId: string): LearnProgress {
  const p = loadLearnProgress()
  if (!p.solved.includes(problemId)) p.solved.push(problemId)
  p.lastProblemId = problemId
  saveLearnProgress(p)
  return p
}

export function isStageCleared(stageId: string, solved: string[]): boolean {
  const stage = STAGES.find((s) => s.id === stageId)
  if (!stage || stage.problems.length === 0) return false
  return stage.problems.every((pr) => solved.includes(pr.id))
}

/** 트랙 내 이전 스테이지를 모두 클리어해야 해금 */
export function isStageUnlocked(stageId: string, solved: string[]): boolean {
  const stage = STAGES.find((s) => s.id === stageId)
  if (!stage) return false
  const trackStages = STAGES.filter((s) => s.track === stage.track).sort((a, b) => a.order - b.order)
  const idx = trackStages.findIndex((s) => s.id === stageId)
  if (idx <= 0) return true
  return trackStages.slice(0, idx).every((s) => isStageCleared(s.id, solved))
}

export function trackClearCount(track: TrackId, solved: string[]): { cleared: number; total: number } {
  const stages = STAGES.filter((s) => s.track === track)
  const cleared = stages.filter((s) => isStageCleared(s.id, solved)).length
  return { cleared, total: stages.length }
}
