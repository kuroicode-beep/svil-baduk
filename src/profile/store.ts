export type AvatarId = 'pine' | 'crane' | 'mountain' | 'river' | 'stone' | 'lantern'

export interface Profile {
  name: string
  avatar: AvatarId
  createdAt: string | null
  level: number
  xp: number
  wins: number
  losses: number
  draws: number
  /** 승리 시 내 총점(집+사석±덤 반영) 최고 */
  highScore: number
  /** 이긴 상대 AI 난이도(1–10) 최고 */
  bestAiLevel: number
  gamesPlayed: number
}

export const AVATARS: { id: AvatarId; labelKo: string; labelEn: string }[] = [
  { id: 'pine', labelKo: '소나무', labelEn: 'Pine' },
  { id: 'crane', labelKo: '학', labelEn: 'Crane' },
  { id: 'mountain', labelKo: '산', labelEn: 'Mountain' },
  { id: 'river', labelKo: '강', labelEn: 'River' },
  { id: 'stone', labelKo: '바둑돌', labelEn: 'Stone' },
  { id: 'lantern', labelKo: '등불', labelEn: 'Lantern' },
]

const KEY = 'svil-baduk-profile'

export function defaultProfile(): Profile {
  return {
    name: '',
    avatar: 'pine',
    createdAt: null,
    level: 1,
    xp: 0,
    wins: 0,
    losses: 0,
    draws: 0,
    highScore: 0,
    bestAiLevel: 0,
    gamesPlayed: 0,
  }
}

export function loadProfile(): Profile {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return defaultProfile()
    return { ...defaultProfile(), ...JSON.parse(raw) }
  } catch {
    return defaultProfile()
  }
}

export function saveProfile(p: Profile) {
  localStorage.setItem(KEY, JSON.stringify(p))
}

export function hasCharacter(p: Profile): boolean {
  return p.name.trim().length > 0 && !!p.createdAt
}

export function avatarLabel(id: AvatarId, lang: string): string {
  const a = AVATARS.find((x) => x.id === id) ?? AVATARS[0]
  return lang === 'ko' ? a.labelKo : a.labelEn
}
