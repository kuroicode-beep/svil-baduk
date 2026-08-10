import type { Point } from '../engine/types'

/**
 * GTP genmove 응답 토큰 → 좌표 또는 pass.
 * GTP는 1행이 아래쪽이라 board 배열 좌표(y=0 이 위)로 뒤집는다 — `pointLabel`의 역함수.
 */
export function parseGenmoveToken(raw: string, size: number): Point | 'pass' | null {
  const token = raw.trim().split(/\s+/).pop()?.toUpperCase()
  if (!token || token === 'PASS' || token === 'RESIGN') return 'pass'
  const letters = 'ABCDEFGHJKLMNOPQRST'
  const col = letters.indexOf(token[0])
  const num = Number(token.slice(1))
  if (col < 0 || col >= size || !Number.isInteger(num) || num < 1 || num > size) return null
  return { x: col, y: size - num }
}
