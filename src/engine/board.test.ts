import { describe, expect, it } from 'vitest'
import { createGame, pass, tryPlay } from './board'

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
