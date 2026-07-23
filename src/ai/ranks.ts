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
  /** KataGo maxVisits (대략) — 저레벨은 엔진 미사용 */
  visits: number
  /** 한 수 최대 초 (GPU에서도 체감 상한) */
  maxTimeSec: number
  /** 내장 AI: 합법적 수 중 무작위 비율 (1=완전랜덤, 0=캡처/중앙 선호) */
  randomness: number
  /**
   * KataGo 후보 선택 온도. 높을수록 약한 수도 자주 둠.
   * 내장 AI만 쓰는 레벨에서는 무시.
   */
  moveTemperature: number
}

export const RANKS: RankOption[] = [
  { id: 'lv1', level: 1, labelKo: '1 · 입문', labelEn: '1 · Beginner', visits: 1, maxTimeSec: 0.1, randomness: 1.0, moveTemperature: 5 },
  { id: 'lv2', level: 2, labelKo: '2 · 왕초보', labelEn: '2 · Novice', visits: 1, maxTimeSec: 0.15, randomness: 0.97, moveTemperature: 4 },
  { id: 'lv3', level: 3, labelKo: '3 · 초급', labelEn: '3 · Easy', visits: 2, maxTimeSec: 0.25, randomness: 0.9, moveTemperature: 3 },
  { id: 'lv4', level: 4, labelKo: '4 · 초급+', labelEn: '4 · Easy+', visits: 4, maxTimeSec: 0.4, randomness: 0.8, moveTemperature: 2.2 },
  { id: 'lv5', level: 5, labelKo: '5 · 중급', labelEn: '5 · Medium', visits: 12, maxTimeSec: 0.7, randomness: 0.45, moveTemperature: 1.4 },
  { id: 'lv6', level: 6, labelKo: '6 · 중급+', labelEn: '6 · Medium+', visits: 24, maxTimeSec: 1.0, randomness: 0.3, moveTemperature: 1.0 },
  { id: 'lv7', level: 7, labelKo: '7 · 상급', labelEn: '7 · Hard', visits: 48, maxTimeSec: 1.3, randomness: 0.18, moveTemperature: 0.6 },
  { id: 'lv8', level: 8, labelKo: '8 · 상급+', labelEn: '8 · Hard+', visits: 100, maxTimeSec: 1.8, randomness: 0.1, moveTemperature: 0.35 },
  { id: 'lv9', level: 9, labelKo: '9 · 유단', labelEn: '9 · Dan', visits: 180, maxTimeSec: 2.4, randomness: 0.05, moveTemperature: 0.2 },
  { id: 'lv10', level: 10, labelKo: '10 · 고수', labelEn: '10 · Expert', visits: 320, maxTimeSec: 3.2, randomness: 0.02, moveTemperature: 0.1 },
]

export const DEFAULT_RANK: RankId = 'lv3'

/** KataGo 신경망은 visits=1이어도 강함 → 입문~초급+는 내장 랜덤 AI만 사용 */
export function usesKataGoEngine(rankId: RankId): boolean {
  return getRank(rankId).level >= 5
}

export function getRank(id: RankId): RankOption {
  return RANKS.find((r) => r.id === id) ?? RANKS[2]
}

export function rankLabel(id: RankId, lang: string): string {
  const r = getRank(id)
  return lang === 'ko' ? r.labelKo : r.labelEn
}
