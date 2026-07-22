/** 급/단 → KataGo visits / 내장 휴리스틱 난이도 */

export type RankId =
  | '30k' | '20k' | '15k' | '10k' | '7k' | '5k' | '3k' | '1k'
  | '1d' | '2d' | '3d' | '5d'

export interface RankOption {
  id: RankId
  labelKo: string
  /** KataGo -v visits (대략) */
  visits: number
  /** 내장 AI: 합법적 수 중 무작위 비율 (1=완전랜덤, 0=캡처/중앙 선호) */
  randomness: number
}

export const RANKS: RankOption[] = [
  { id: '30k', labelKo: '30급 (입문)', visits: 2, randomness: 0.95 },
  { id: '20k', labelKo: '20급', visits: 4, randomness: 0.85 },
  { id: '15k', labelKo: '15급', visits: 8, randomness: 0.7 },
  { id: '10k', labelKo: '10급', visits: 16, randomness: 0.55 },
  { id: '7k', labelKo: '7급', visits: 32, randomness: 0.4 },
  { id: '5k', labelKo: '5급', visits: 64, randomness: 0.3 },
  { id: '3k', labelKo: '3급', visits: 128, randomness: 0.2 },
  { id: '1k', labelKo: '1급', visits: 256, randomness: 0.12 },
  { id: '1d', labelKo: '초단', visits: 400, randomness: 0.08 },
  { id: '2d', labelKo: '2단', visits: 600, randomness: 0.05 },
  { id: '3d', labelKo: '3단', visits: 900, randomness: 0.03 },
  { id: '5d', labelKo: '5단', visits: 1600, randomness: 0.01 },
]

export function getRank(id: RankId): RankOption {
  return RANKS.find((r) => r.id === id) ?? RANKS[0]
}
