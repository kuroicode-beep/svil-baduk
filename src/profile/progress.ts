import { getRank, type RankId } from '../ai/ranks'
import type { Profile } from './store'

/** 다음 레벨까지 필요 XP */
export function xpToNextLevel(level: number): number {
  return 40 + level * 30
}

export function applyXp(profile: Profile, gained: number): { profile: Profile; leveledUp: number } {
  let level = profile.level
  let xp = profile.xp + Math.max(0, gained)
  let leveledUp = 0
  let guard = 0
  while (xp >= xpToNextLevel(level) && guard < 50) {
    xp -= xpToNextLevel(level)
    level += 1
    leveledUp += 1
    guard += 1
  }
  return {
    profile: { ...profile, level, xp },
    leveledUp,
  }
}

export function xpForResult(opts: {
  won: boolean
  draw: boolean
  rankId: RankId
}): number {
  const lv = getRank(opts.rankId).level
  if (opts.draw) return 8 + lv
  if (opts.won) return 20 + lv * 8
  return 5 + Math.floor(lv / 2)
}

export interface GameRecordInput {
  myColor: 1 | 2
  winner: 0 | 1 | 2
  myScore: number
  rankId: RankId
}

export interface GameRecordResult {
  profile: Profile
  leveledUp: number
  xpGained: number
  newHighScore: boolean
  newBestAi: boolean
}

export function recordSoloResult(profile: Profile, input: GameRecordInput): GameRecordResult {
  const won = input.winner === input.myColor
  const draw = input.winner === 0
  const xpGained = xpForResult({ won, draw, rankId: input.rankId })
  const aiLevel = getRank(input.rankId).level

  let next: Profile = {
    ...profile,
    gamesPlayed: profile.gamesPlayed + 1,
    wins: profile.wins + (won ? 1 : 0),
    losses: profile.losses + (!won && !draw ? 1 : 0),
    draws: profile.draws + (draw ? 1 : 0),
  }

  let newHighScore = false
  if (won && input.myScore > next.highScore) {
    next.highScore = input.myScore
    newHighScore = true
  }

  let newBestAi = false
  if (won && aiLevel > next.bestAiLevel) {
    next.bestAiLevel = aiLevel
    newBestAi = true
  }

  const leveled = applyXp(next, xpGained)
  return {
    profile: leveled.profile,
    leveledUp: leveled.leveledUp,
    xpGained,
    newHighScore,
    newBestAi,
  }
}
