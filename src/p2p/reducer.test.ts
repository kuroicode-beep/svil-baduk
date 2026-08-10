// src/p2p/reducer.test.ts — PeerJS 없이 프로토콜 로직만 검증
import { describe, expect, it } from 'vitest'
import { tryPlay } from '../engine/board'
import { applyP2PMessage, initialMultiState } from './reducer'

describe('applyP2PMessage', () => {
  it('host answers sync-request with hello and starts a fresh game', () => {
    const host = { ...initialMultiState(13), amHost: true, hostColor: 2 as const }
    const { state, effects } = applyP2PMessage(host, { type: 'sync-request' })

    expect(state.phase).toBe('play')
    expect(state.connected).toBe(true)
    expect(state.myColor).toBe(2)
    expect(state.game.size).toBe(13)
    expect(state.game.history).toHaveLength(0)
    expect(effects).toEqual([
      { kind: 'send', msg: { type: 'hello', name: 'host', size: 13, hostColor: 2 } },
    ])
  })

  it('ignores sync-request when not the host', () => {
    const guest = { ...initialMultiState(9), amHost: false }
    const { state, effects } = applyP2PMessage(guest, { type: 'sync-request' })
    expect(state).toBe(guest)
    expect(effects).toEqual([])
  })

  it('guest adopts the host size and takes the opposite colour', () => {
    const guest = initialMultiState(9)
    const { state, effects } = applyP2PMessage(guest, {
      type: 'hello',
      name: 'host',
      size: 19,
      hostColor: 1,
    })

    expect(state.amHost).toBe(false)
    expect(state.size).toBe(19)
    expect(state.game.size).toBe(19)
    expect(state.myColor).toBe(2) // 호스트가 흑이면 게스트는 백
    expect(state.phase).toBe('play')
    expect(effects).toEqual([{ kind: 'send', msg: { type: 'accept', name: 'guest' } }])
  })

  it('applies a remote move and asks for a sound exactly once', () => {
    let s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    const r = tryPlay(s.game, 3, 3)
    expect(r.ok).toBe(true)
    if (!r.ok) return

    const out = applyP2PMessage(s, { type: 'move', move: r.move })
    expect(out.state.game.history).toHaveLength(1)
    expect(out.state.game.toPlay).toBe(2)
    expect(out.effects).toEqual([{ kind: 'sound' }])
  })

  it('is pure — calling twice does not double-apply', () => {
    const s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    const r = tryPlay(s.game, 4, 4)
    if (!r.ok) return
    const a = applyP2PMessage(s, { type: 'move', move: r.move })
    const b = applyP2PMessage(s, { type: 'move', move: r.move })
    expect(a.state.game.history).toHaveLength(1)
    expect(b.state.game.history).toHaveLength(1)
    expect(s.game.history).toHaveLength(0) // 입력 상태는 그대로
  })

  it('drops an illegal remote move instead of corrupting the board', () => {
    let s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    const first = tryPlay(s.game, 3, 3)
    if (!first.ok) return
    s = applyP2PMessage(s, { type: 'move', move: first.move }).state

    // 같은 자리에 또 두는 메시지 — 무시되어야 한다
    const out = applyP2PMessage(s, { type: 'move', move: { ...first.move, player: 2 } })
    expect(out.state.game.history).toHaveLength(1)
    expect(out.effects).toEqual([])
  })

  it('applies a remote pass', () => {
    let s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    s = applyP2PMessage(s, {
      type: 'move',
      move: { player: 1, x: -1, y: -1, pass: true, captured: [] },
    }).state
    expect(s.game.history[0].pass).toBe(true)
    expect(s.game.consecutivePasses).toBe(1)
  })

  it('ends the game on a remote resign', () => {
    let s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    s = applyP2PMessage(s, { type: 'resign', player: 2 }).state
    expect(s.game.ended).toBe(true)
    expect(s.game.resignedBy).toBe(2)
  })

  it('accept flips both sides into play', () => {
    const { state } = applyP2PMessage(initialMultiState(9), { type: 'accept', name: 'guest' })
    expect(state.phase).toBe('play')
    expect(state.connected).toBe(true)
  })

  // 현재 프로토콜의 알려진 한계 — Wave 3에서 고친다. 지금은 동작을 고정만 해둔다.
  it('KNOWN GAP: applies remote moves using the receiver turn, ignoring move.player', () => {
    let s = applyP2PMessage(initialMultiState(9), { type: 'sync-request' }).state
    // 흑 차례인데 백이 보낸 수를 그대로 적용해 버린다
    const out = applyP2PMessage(s, {
      type: 'move',
      move: { player: 2, x: 3, y: 3, captured: [] },
    })
    expect(out.state.game.history[0].player).toBe(1)
  })
})
