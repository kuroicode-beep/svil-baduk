import type { Point } from '../engine/types'

/** GTP genmove 응답 토큰 → 좌표 또는 pass */
export function parseGenmoveToken(raw: string): Point | 'pass' | null {
  const token = raw.trim().split(/\s+/).pop()?.toUpperCase()
  if (!token || token === 'PASS' || token === 'RESIGN') return 'pass'
  const letters = 'ABCDEFGHJKLMNOPQRST'
  const col = letters.indexOf(token[0])
  const row = Number(token.slice(1)) - 1
  if (col < 0 || Number.isNaN(row) || row < 0) return null
  return { x: col, y: row }
}
