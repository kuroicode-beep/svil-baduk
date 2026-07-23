import type { RankId } from '../ai/ranks'
import type { BoardSize, GameState, Move, Player } from '../engine/types'

const KEY = 'svil-baduk-solo-snapshot'

export type SoloSnapshot = {
  v: 1
  savedAt: string
  size: BoardSize
  rankId: RankId
  myColor: Player
  state: GameState
}

function isMove(m: unknown): m is Move {
  if (!m || typeof m !== 'object') return false
  const o = m as Move
  return (
    (o.player === 1 || o.player === 2) &&
    typeof o.x === 'number' &&
    typeof o.y === 'number' &&
    Array.isArray(o.captured)
  )
}

function isGameState(s: unknown): s is GameState {
  if (!s || typeof s !== 'object') return false
  const g = s as GameState
  return (
    (g.size === 9 || g.size === 13 || g.size === 19) &&
    Array.isArray(g.board) &&
    g.board.length === g.size * g.size &&
    (g.toPlay === 1 || g.toPlay === 2) &&
    Array.isArray(g.history) &&
    g.history.every(isMove)
  )
}

export function loadSoloSnapshot(): SoloSnapshot | null {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return null
    const data = JSON.parse(raw) as SoloSnapshot
    if (data?.v !== 1 || !isGameState(data.state)) return null
    if (data.size !== data.state.size) return null
    if (data.myColor !== 1 && data.myColor !== 2) return null
    return data
  } catch {
    return null
  }
}

export function saveSoloSnapshot(snap: Omit<SoloSnapshot, 'v' | 'savedAt'>): void {
  const payload: SoloSnapshot = {
    v: 1,
    savedAt: new Date().toISOString(),
    ...snap,
  }
  localStorage.setItem(KEY, JSON.stringify(payload))
}

export function clearSoloSnapshot(): void {
  localStorage.removeItem(KEY)
}
