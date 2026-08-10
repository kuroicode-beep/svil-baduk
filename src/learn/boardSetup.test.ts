// src/learn/boardSetup.test.ts
import { describe, expect, it } from 'vitest'
import { boardHash, idx, tryPlay } from '../engine/board'
import { emptyRows, parseSetup } from './boardSetup'

describe('parseSetup', () => {
  it('places stones without capturing or flipping the turn', () => {
    const g = parseSetup(9, ['.........', '..BW.....', '.........'], 2)
    expect(g.board[idx(9, 2, 1)]).toBe(1)
    expect(g.board[idx(9, 3, 1)]).toBe(2)
    expect(g.toPlay).toBe(2)
    expect(g.history).toHaveLength(0)
    expect(g.captures[1]).toBe(0)
    expect(g.captures[2]).toBe(0)
  })

  it('seeds positionHashes from the setup position, not the empty board', () => {
    const rows = emptyRows(9)
    rows[3] = '...BW....'
    const g = parseSetup(9, rows, 1)
    expect(g.positionHashes).toEqual([boardHash(g.board)])
    // 회귀: 예전엔 빈 판 해시가 들어 있었다
    expect(g.positionHashes[0]).not.toBe(boardHash(Array(81).fill(0)))
  })

  it('runs the ko rule correctly from a setup position', () => {
    // 표준 패 모양. 흑 (2,2)는 활로가 (3,2) 하나뿐이고,
    // 백이 (3,2)에 두어 따내면 그 백 돌도 활로가 (2,2) 하나뿐 → 패.
    const rows = emptyRows(9)
    rows[1] = '..WB.....'
    rows[2] = '.WB.B....'
    rows[3] = '..WB.....'
    const g = parseSetup(9, rows, 2)

    const take = tryPlay(g, 3, 2)
    expect(take.ok).toBe(true)
    if (!take.ok) return
    expect(take.move.captured).toEqual([{ x: 2, y: 2 }])
    expect(take.state.koPoint).toEqual({ x: 2, y: 2 })

    // 즉시 되따냄은 패로 금지 — 배치 위치가 그대로 재현되는 수
    const back = tryPlay(take.state, 2, 2)
    expect(back.ok).toBe(false)
    if (!back.ok) expect(back.reason).toBe('ko')
  })

  it('rejects a move that recreates the setup position (superko)', () => {
    // 배치 해시가 시딩되어 있지 않으면 이 수가 통과해 버린다 — 회귀 방지
    const rows = emptyRows(9)
    rows[1] = '..WB.....'
    rows[2] = '.WB.B....'
    rows[3] = '..WB.....'
    const g = parseSetup(9, rows, 2)

    const take = tryPlay(g, 3, 2)
    expect(take.ok).toBe(true)
    if (!take.ok) return
    // 패 금지를 우회해 강제로 되따냄을 시도 → 판이 배치 위치와 같아짐
    const noKo = { ...take.state, koPoint: null }
    const back = tryPlay(noKo, 2, 2)
    expect(back.ok).toBe(false)
    if (!back.ok) expect(back.reason).toBe('superko')
  })
})
