/**
 * 하위 호환 — 기존 따냄 퍼즐 API.
 * 신규 코스는 curriculum.ts 사용.
 */
import { problemState } from './boardSetup'
import { STAGES } from './curriculum'
import type { LearnProblem, ProblemGoal } from './types'

export type PuzzleGoal = ProblemGoal
export type Puzzle = LearnProblem

export function puzzleState(p: LearnProblem) {
  return problemState(p)
}

/** 기존 테스트/UI용: 기본 트랙 2스테이지 따냄 문제 */
export const PUZZLES: LearnProblem[] = STAGES.find((s) => s.id === 'basics-2')?.problems ?? []
