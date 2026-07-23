/** 난이도 10단계 → KataGo visits / 내장 휴리스틱 */

export type RankId =
  | 'lv1'
  | 'lv2'
  | 'lv3'
  | 'lv4'
  | 'lv5'
  | 'lv6'
  | 'lv7'
  | 'lv8'
  | 'lv9'
  | 'lv10'

export interface RankOption {
  id: RankId
  /** 1–10 */
  level: number
  labelKo: string
  labelEn: string
  /** KataGo maxVisits (대략) */
  visits: number
  /** 한 수 최대 초 (GPU에서도 체감 상한) */
  maxTimeSec: number
  /** 내장 AI: 합법적 수 중 무작위 비율 (1=완전랜덤, 0=캡처/중앙 선호) */
  randomness: number
}

export const RANKS: RankOption[] = [
  { id: 'lv1', level: 1, labelKo: '1 · 입문', labelEn: '1 · Beginner', visits: 2, maxTimeSec: 0.3, randomness: 0.95 },
  { id: 'lv2', level: 2, labelKo: '2 · 왕초보', labelEn: '2 · Novice', visits: 4, maxTimeSec: 0.4, randomness: 0.85 },
  { id: 'lv3', level: 3, labelKo: '3 · 초급', labelEn: '3 · Easy', visits: 8, maxTimeSec: 0.5, randomness: 0.7 },
  { id: 'lv4', level: 4, labelKo: '4 · 초급+', labelEn: '4 · Easy+', visits: 16, maxTimeSec: 0.7, randomness: 0.55 },
  { id: 'lv5', level: 5, labelKo: '5 · 중급', labelEn: '5 · Medium', visits: 32, maxTimeSec: 1.0, randomness: 0.4 },
  { id: 'lv6', level: 6, labelKo: '6 · 중급+', labelEn: '6 · Medium+', visits: 64, maxTimeSec: 1.2, randomness: 0.28 },
  { id: 'lv7', level: 7, labelKo: '7 · 상급', labelEn: '7 · Hard', visits: 100, maxTimeSec: 1.5, randomness: 0.18 },
  { id: 'lv8', level: 8, labelKo: '8 · 상급+', labelEn: '8 · Hard+', visits: 160, maxTimeSec: 2.0, randomness: 0.1 },
  { id: 'lv9', level: 9, labelKo: '9 · 유단', labelEn: '9 · Dan', visits: 250, maxTimeSec: 2.5, randomness: 0.05 },
  { id: 'lv10', level: 10, labelKo: '10 · 고수', labelEn: '10 · Expert', visits: 400, maxTimeSec: 3.5, randomness: 0.02 },
]

export const DEFAULT_RANK: RankId = 'lv3'

export function getRank(id: RankId): RankOption {
  return RANKS.find((r) => r.id === id) ?? RANKS[2]
}

export function rankLabel(id: RankId, lang: string): string {
  const r = getRank(id)
  return lang === 'ko' ? r.labelKo : r.labelEn
}
