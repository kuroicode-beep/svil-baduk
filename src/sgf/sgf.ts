import { createGame, pass, tryPlay } from '../engine/board'
import type { BoardSize, GameState, Move } from '../engine/types'

const LETTERS = 'abcdefghijklmnopqrstuvwxyz'

function sgfCoord(x: number, y: number): string {
  return LETTERS[x] + LETTERS[y]
}

function parseSgfCoord(s: string): { x: number; y: number } | 'pass' | null {
  if (!s || s === '' || s === 'tt') return 'pass'
  if (s.length < 2) return null
  const x = LETTERS.indexOf(s[0])
  const y = LETTERS.indexOf(s[1])
  if (x < 0 || y < 0) return null
  return { x, y }
}

/** GameState → 간단 FF[4] SGF (루트+수순) */
export function encodeSgf(state: GameState, meta?: { black?: string; white?: string }): string {
  const parts = [
    '(;',
    'FF[4]',
    'GM[1]',
    `SZ[${state.size}]`,
    `AP[SVIL-Baduk:0.3]`,
    meta?.black ? `PB[${escapeSgf(meta.black)}]` : '',
    meta?.white ? `PW[${escapeSgf(meta.white)}]` : '',
  ].filter(Boolean)

  for (const m of state.history) {
    const color = m.player === 1 ? 'B' : 'W'
    if (m.pass) parts.push(`;${color}[]`)
    else parts.push(`;${color}[${sgfCoord(m.x, m.y)}]`)
  }
  parts.push(')')
  return parts.join('')
}

function escapeSgf(s: string): string {
  return s.replace(/\\/g, '\\\\').replace(/]/g, '\\]')
}

export type SgfLoadResult =
  | { ok: true; state: GameState; size: BoardSize }
  | { ok: false; reason: string }

/** 최소 SGF 파서: SZ + B[]/W[] 수순 */
export function decodeSgf(text: string): SgfLoadResult {
  const cleaned = text.replace(/\s+/g, ' ').trim()
  if (!cleaned.includes('(')) return { ok: false, reason: 'not_sgf' }

  const sz = cleaned.match(/SZ\[(\d+)\]/i)
  const sizeNum = sz ? Number(sz[1]) : 19
  if (sizeNum !== 9 && sizeNum !== 13 && sizeNum !== 19) {
    return { ok: false, reason: 'unsupported_size' }
  }
  const size = sizeNum as BoardSize

  const moveRe = /;([BW])\[([a-z]{0,2})\]/gi
  const moves: { color: 'B' | 'W'; raw: string }[] = []
  let m: RegExpExecArray | null
  while ((m = moveRe.exec(cleaned))) {
    moves.push({ color: m[1].toUpperCase() as 'B' | 'W', raw: m[2] })
  }

  let state = createGame(size)
  for (const mv of moves) {
    const expect = state.toPlay === 1 ? 'B' : 'W'
    if (mv.color !== expect) {
      return { ok: false, reason: 'turn_mismatch' }
    }
    const coord = parseSgfCoord(mv.raw)
    if (coord === 'pass' || coord === null) {
      const r = pass(state)
      if (!r.ok) return { ok: false, reason: 'pass_failed' }
      state = r.state
      continue
    }
    const r = tryPlay(state, coord.x, coord.y)
    if (!r.ok) return { ok: false, reason: `illegal_${coord.x}_${coord.y}` }
    state = r.state
  }

  return { ok: true, state, size }
}

/** history를 n수까지 재생 */
export function replayTo(history: Move[], size: BoardSize, ply: number): GameState {
  let state = createGame(size)
  const n = Math.max(0, Math.min(ply, history.length))
  for (let i = 0; i < n; i++) {
    const mv = history[i]
    if (mv.pass) {
      const r = pass(state)
      if (!r.ok) break
      state = r.state
    } else {
      const r = tryPlay(state, mv.x, mv.y)
      if (!r.ok) break
      state = r.state
    }
  }
  return state
}

export function downloadSgf(filename: string, content: string) {
  const blob = new Blob([content], { type: 'application/x-go-sgf' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
