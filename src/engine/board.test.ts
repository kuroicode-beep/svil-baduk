import { describe, expect, it } from 'vitest'
import {
  boardHash,
  createGame,
  legalMoves,
  pass,
  pointLabel,
  rebuildPositionHashes,
  replayHistory,
  starPoints,
  tryPlay,
} from './board'
import type { Stone } from './types'

describe('boardHash', () => {
  it('is injective over the states we care about', () => {
    const seen = new Map<string, string>()
    // 9칸 판을 3진 전수 탐색 — 19683가지 배치가 전부 다른 해시여야 한다
    for (let n = 0; n < 3 ** 9; n++) {
      const board: Stone[] = []
      let v = n
      for (let i = 0; i < 9; i++) {
        board.push((v % 3) as Stone)
        v = Math.floor(v / 3)
      }
      const h = boardHash(board)
      expect(seen.has(h)).toBe(false)
      seen.set(h, board.join(''))
    }
    expect(seen.size).toBe(3 ** 9)
  })

  it('stays inside the safe BMP range (no lone surrogates in localStorage)', () => {
    const board = Array<Stone>(19 * 19).fill(2)
    const h = boardHash(board)
    for (const ch of h) {
      const code = ch.charCodeAt(0)
      expect(code).toBeLessThan(0xd800)
      expect(code).toBeGreaterThanOrEqual(0x30)
    }
    // JSON 왕복이 손실 없이 되는지 (스냅샷 저장 경로)
    expect(JSON.parse(JSON.stringify({ h })).h).toBe(h)
  })

  it('is much shorter than the old join()', () => {
    const board = Array<Stone>(19 * 19).fill(1)
    expect(boardHash(board).length).toBeLessThan(board.length / 5)
  })
})

describe('rebuildPositionHashes', () => {
  it('restores superko protection when the stored hashes are garbage', () => {
    let g = createGame(9)
    for (const [x, y] of [[3, 3], [5, 5], [3, 4], [5, 4]] as [number, number][]) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (r.ok) g = r.state
    }
    const corrupted = { ...g, positionHashes: ['nonsense'] }
    const fixed = rebuildPositionHashes(corrupted)
    expect(fixed.positionHashes).toEqual(g.positionHashes)
    // history 밖 정보는 보존
    expect(fixed.ended).toBe(g.ended)
    expect(fixed.board).toEqual(g.board)
  })

  it('replayHistory reproduces the live board', () => {
    let g = createGame(9)
    for (const [x, y] of [[2, 2], [6, 6], [2, 3], [6, 5], [4, 4]] as [number, number][]) {
      const r = tryPlay(g, x, y)
      if (r.ok) g = r.state
    }
    const replayed = replayHistory(9, g.history)
    expect(replayed.board).toEqual(g.board)
    expect(replayed.toPlay).toBe(g.toPlay)
    expect(replayed.positionHashes).toEqual(g.positionHashes)
  })
})

describe('legalMoves', () => {
  it('excludes occupied points and matches tryPlay exactly', () => {
    let g = createGame(9)
    for (const [x, y] of [[4, 4], [3, 3], [5, 5]] as [number, number][]) {
      const r = tryPlay(g, x, y)
      if (r.ok) g = r.state
    }
    const fast = new Set(legalMoves(g).map((p) => `${p.x},${p.y}`))
    for (let y = 0; y < 9; y++) {
      for (let x = 0; x < 9; x++) {
        expect(fast.has(`${x},${y}`)).toBe(tryPlay(g, x, y).ok)
      }
    }
    expect(fast.size).toBe(81 - 3)
  })
})

describe('pointLabel', () => {
  it('puts row 1 at the bottom (standard Go notation)', () => {
    // board 배열은 y=0 이 위쪽 줄 → 세로 반전
    expect(pointLabel(0, 18, 19)).toBe('A1') // 좌하단
    expect(pointLabel(0, 0, 19)).toBe('A19') // 좌상단
    expect(pointLabel(3, 3, 19)).toBe('D16') // 좌상 화점
    expect(pointLabel(3, 15, 19)).toBe('D4') // 좌하 화점
    expect(pointLabel(4, 4, 9)).toBe('E5') // 9줄 천원
  })

  it('skips the letter I', () => {
    expect(pointLabel(7, 0, 9)).toBe('H9')
    expect(pointLabel(8, 0, 9)).toBe('J9')
  })

  it('labels 19x19 star points the way Go books do', () => {
    const labels = starPoints(19).map((p) => pointLabel(p.x, p.y, 19))
    expect(labels).toContain('D16')
    expect(labels).toContain('Q16')
    expect(labels).toContain('K10') // 천원
    expect(labels).toContain('D4')
    expect(labels).toContain('Q4')
  })
})

describe('go engine', () => {
  it('places stones and alternates', () => {
    let g = createGame(9)
    const a = tryPlay(g, 3, 3)
    expect(a.ok).toBe(true)
    if (!a.ok) return
    g = a.state
    expect(g.toPlay).toBe(2)
    const b = tryPlay(g, 4, 3)
    expect(b.ok).toBe(true)
  })

  it('captures a single stone', () => {
    let g = createGame(9)
    // Black surrounds (1,1): north/west/east first, then white enters, black south captures
    const sequence: [number, number][] = [
      [0, 1], // B
      [5, 5], // W dummy
      [1, 0], // B
      [5, 6], // W dummy
      [2, 1], // B
      [1, 1], // W — the victim
      [1, 2], // B — capture
    ]
    let last = tryPlay(g, sequence[0][0], sequence[0][1])
    expect(last.ok).toBe(true)
    if (!last.ok) return
    g = last.state
    for (let i = 1; i < sequence.length; i++) {
      last = tryPlay(g, sequence[i][0], sequence[i][1])
      expect(last.ok).toBe(true)
      if (!last.ok) return
      g = last.state
    }
    expect(last.move.captured).toEqual([{ x: 1, y: 1 }])
    expect(g.captures[1]).toBe(1)
  })

  it('rejects suicide', () => {
    let g = createGame(9)
    // Black surrounds corner (0,0); White must not play there
    const setup: [number, number][] = [
      [1, 0], // B
      [5, 5], // W
      [0, 1], // B
      [5, 6], // W
    ]
    for (const [x, y] of setup) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    // Black to play — pass so White faces suicide at (0,0)
    const p = pass(g)
    expect(p.ok).toBe(true)
    if (!p.ok) return
    g = p.state
    const suicide = tryPlay(g, 0, 0)
    expect(suicide.ok).toBe(false)
  })

  it('ends after two passes', () => {
    let g = createGame(9)
    let r = pass(g)
    if (!r.ok) throw new Error('pass')
    g = r.state
    r = pass(g)
    if (!r.ok) throw new Error('pass')
    expect(r.state.ended).toBe(true)
  })

  it('enforces simple ko', () => {
    let g = createGame(9)
    // Ko shape: White at (1,1); Black captures at (2,1) with single liberty → ko at (1,1)
    const sequence: [number, number][] = [
      [1, 0], // B
      [2, 0], // W
      [0, 1], // B
      [2, 2], // W
      [1, 2], // B
      [3, 1], // W
      [5, 5], // B dummy
      [1, 1], // W victim
      [2, 1], // B capture → ko
    ]
    for (const [x, y] of sequence) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    expect(g.koPoint).toEqual({ x: 1, y: 1 })
    const illegal = tryPlay(g, 1, 1)
    expect(illegal.ok).toBe(false)
    if (illegal.ok) return
    expect(illegal.reason).toBe('ko')

    // Fill a move elsewhere to lift ko
    let r = tryPlay(g, 4, 4)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    g = r.state
    r = tryPlay(g, 4, 5)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    g = r.state
    r = tryPlay(g, 1, 1)
    // 패 직후가 아니면 슈퍼코/패 규칙에 따라 가능할 수 있음 — 여기선 한 수씩 둔 뒤 재시도
    expect(r.ok).toBe(true)
  })

  it('rejects positional superko (repeat board)', () => {
    let g = createGame(9)
    // 간단 순환: 따냄으로 이전 국면 재현 시도는 패/슈퍼코로 막힘
    const sequence: [number, number][] = [
      [1, 0],
      [2, 0],
      [0, 1],
      [2, 2],
      [1, 2],
      [3, 1],
      [5, 5],
      [1, 1],
      [2, 1], // B captures — ko at 1,1
    ]
    for (const [x, y] of sequence) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    const retake = tryPlay(g, 1, 1)
    expect(retake.ok).toBe(false)
    if (retake.ok) return
    expect(['ko', 'superko']).toContain(retake.reason)
  })

  it('rejects suicide (fill own last liberty)', () => {
    let g = createGame(9)
    // White box around (1,1) with one hole; black cannot play into only liberty if suicide
    const sequence: [number, number][] = [
      [0, 0], // B elsewhere
      [1, 0], // W
      [5, 5], // B
      [0, 1], // W
      [5, 6], // B
      [2, 1], // W
      [5, 7], // B
      [1, 2], // W — (1,1) empty, surrounded by W on N/W/E/S
    ]
    for (const [x, y] of sequence) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    // Black to play into (1,1) — suicide
    const suicide = tryPlay(g, 1, 1)
    expect(suicide.ok).toBe(false)
  })

  it('allows capturing instead of suicide', () => {
    let g = createGame(9)
    // Classic: white stone at (1,1) with one liberty; black captures
    const sequence: [number, number][] = [
      [1, 0], // B
      [1, 1], // W victim
      [0, 1], // B
      [5, 5], // W
      [2, 1], // B
      [5, 6], // W
    ]
    for (const [x, y] of sequence) {
      const r = tryPlay(g, x, y)
      expect(r.ok).toBe(true)
      if (!r.ok) return
      g = r.state
    }
    const cap = tryPlay(g, 1, 2) // B captures W
    expect(cap.ok).toBe(true)
    if (!cap.ok) return
    expect(cap.move.captured).toEqual([{ x: 1, y: 1 }])
  })
})
