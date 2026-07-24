import type { BoardSize, Player, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'

export type TrackId = 'basics' | 'fuseki' | 'tsumego'

/** capture=따냄, place=정답 교차점 착수, kill=상대 사, live=살림(급소) */
export type ProblemGoal = 'capture' | 'place' | 'kill' | 'live'

export type LocString = Partial<Record<Lang, string>> & { ko: string }

export interface LearnProblem {
  id: string
  title: LocString
  goalLabel: LocString
  goal: ProblemGoal
  size: BoardSize
  toPlay: Player
  setup: string[]
  solutions: Point[]
  hint: LocString
  /** 정답 후 짧은 해설 */
  note?: LocString
}

export interface LearnStage {
  id: string
  track: TrackId
  order: number
  title: LocString
  /** 스테이지 입문 — 교재 개념 요약 */
  blurb: LocString
  /** 참고 교재(공개 교육 전통, 저작권 문제 복제 아님) */
  refs: LocString
  problems: LearnProblem[]
}

export function loc(lang: Lang, s: LocString): string {
  return s[lang] ?? s.en ?? s.ko
}
