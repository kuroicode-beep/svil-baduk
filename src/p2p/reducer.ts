// src/p2p/reducer.ts — P2P 메시지 처리의 순수 함수 부분
//
// PeerJS·React 없이 테스트할 수 있도록 화면(Multi.tsx)에서 분리했다.
// 부수효과(전송·소리)는 실행하지 않고 목록으로 돌려준다 — StrictMode에서
// 리듀서가 두 번 불려도 소리가 두 번 나지 않는다.

import { createGame, pass, resign, tryPlay } from '../engine/board'
import type { BoardSize, GameState, Player } from '../engine/types'
import type { P2PMessage } from './session'

export interface MultiState {
  phase: 'lobby' | 'play'
  amHost: boolean
  /** 호스트가 고른 판 크기 — 게스트는 hello로 덮어쓴다 */
  size: BoardSize
  hostColor: Player
  myColor: Player
  connected: boolean
  /** i18n 키 (문구가 아니라 키를 담아 화면에서 번역) */
  errorKey: string
  game: GameState
}

export type P2PEffect =
  | { kind: 'send'; msg: P2PMessage }
  | { kind: 'sound' }

export function initialMultiState(size: BoardSize = 9): MultiState {
  return {
    phase: 'lobby',
    amHost: true,
    size,
    hostColor: 1,
    myColor: 1,
    connected: false,
    errorKey: '',
    game: createGame(size),
  }
}

function opponentOf(p: Player): Player {
  return p === 1 ? 2 : 1
}

/**
 * 수신 메시지를 상태에 반영한다.
 * 알 수 없거나 지금 단계에서 의미 없는 메시지는 상태를 그대로 둔다.
 */
export function applyP2PMessage(
  s: MultiState,
  msg: P2PMessage,
): { state: MultiState; effects: P2PEffect[] } {
  switch (msg.type) {
    // 게스트가 접속 → 호스트가 대국 조건을 알려주고 새 판으로 시작
    case 'sync-request': {
      if (!s.amHost) return { state: s, effects: [] }
      return {
        state: {
          ...s,
          myColor: s.hostColor,
          game: createGame(s.size),
          connected: true,
          errorKey: '',
          phase: 'play',
        },
        effects: [
          {
            kind: 'send',
            msg: { type: 'hello', name: 'host', size: s.size, hostColor: s.hostColor },
          },
        ],
      }
    }

    case 'hello': {
      return {
        state: {
          ...s,
          amHost: false,
          size: msg.size,
          hostColor: msg.hostColor,
          myColor: opponentOf(msg.hostColor),
          game: createGame(msg.size),
          connected: true,
          errorKey: '',
          phase: 'play',
        },
        effects: [{ kind: 'send', msg: { type: 'accept', name: 'guest' } }],
      }
    }

    case 'accept': {
      return {
        state: { ...s, connected: true, errorKey: '', phase: 'play' },
        effects: [],
      }
    }

    case 'move': {
      if (msg.move.pass) {
        const r = pass(s.game)
        return r.ok ? { state: { ...s, game: r.state }, effects: [] } : { state: s, effects: [] }
      }
      const r = tryPlay(s.game, msg.move.x, msg.move.y)
      if (!r.ok) return { state: s, effects: [] }
      return { state: { ...s, game: r.state }, effects: [{ kind: 'sound' }] }
    }

    case 'resign': {
      return { state: { ...s, game: resign(s.game, msg.player) }, effects: [] }
    }

    // chat 은 타입만 있고 아직 보내는 쪽이 없다 (Wave 3에서 프리셋 문구로)
    default:
      return { state: s, effects: [] }
  }
}
