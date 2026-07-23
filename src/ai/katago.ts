/**
 * KataGo GTP 클라이언트.
 * 브라우저 → 로컬 HTTP 브리지(scripts/katago-bridge.mjs) → katago.exe stdin/stdout
 *
 * 보드 상태는 증분 동기화 (매 수 clear_board+전체 재착수 금지 — GPU여도 체감이 크게 느려짐).
 */

import type { GameState, Move, Point } from '../engine/types'
import { pointLabel } from '../engine/board'
import { getRank, type RankId } from './ranks'
import { parseGenmoveToken } from './gtpParse'

export type KataGoTransport = {
  send: (line: string) => Promise<string>
  isConnected: () => boolean
}

let transport: KataGoTransport | null = null

/** 엔진에 올라간 착수 이력 (증분 play용) */
let engineSize = 0
let engineHistory: Move[] = []

export function setKataGoTransport(t: KataGoTransport | null) {
  transport = t
  engineSize = 0
  engineHistory = []
}

export function isKataGoAvailable(): boolean {
  return !!transport?.isConnected()
}

function gtpCoord(x: number, y: number): string {
  return pointLabel(x, y)
}

function colorToken(player: 1 | 2): string {
  return player === 1 ? 'B' : 'W'
}

async function playMove(m: Move): Promise<void> {
  if (!transport) return
  if (m.pass) {
    await transport.send(`play ${colorToken(m.player)} pass`)
  } else {
    await transport.send(`play ${colorToken(m.player)} ${gtpCoord(m.x, m.y)}`)
  }
}

function historyPrefixMatch(a: Move[], b: Move[]): number {
  const n = Math.min(a.length, b.length)
  let i = 0
  for (; i < n; i++) {
    const x = a[i]
    const y = b[i]
    if (
      x.player !== y.player ||
      x.pass !== y.pass ||
      (!x.pass && (x.x !== y.x || x.y !== y.y))
    ) {
      break
    }
  }
  return i
}

/** 엔진 보드를 state.history 와 맞춤 */
async function syncBoard(state: GameState): Promise<void> {
  if (!transport?.isConnected()) throw new Error('not_connected')

  const common = historyPrefixMatch(engineHistory, state.history)

  // 사이즈 변경·되돌리기·분기 → 전체 재동기화
  if (engineSize !== state.size || common < engineHistory.length) {
    await transport.send(`boardsize ${state.size}`)
    await transport.send('clear_board')
    engineSize = state.size
    engineHistory = []
    for (const m of state.history) {
      await playMove(m)
      engineHistory.push(m)
    }
    return
  }

  // 공통 prefix 이후 새 수만 play
  for (let i = common; i < state.history.length; i++) {
    const m = state.history[i]
    await playMove(m)
    engineHistory.push(m)
  }
}

export async function katagoGenmove(
  state: GameState,
  rankId: RankId,
): Promise<Point | 'pass' | null> {
  if (!transport?.isConnected()) return null
  const rank = getRank(rankId)
  const color = colorToken(state.toPlay)

  await syncBoard(state)

  // visits / 시간 상한 — 5060 Ti급에서도 난이도별 체감 반응 유지
  try {
    await transport.send(`kata-set-param maxVisits ${rank.visits}`)
  } catch {
    /* optional */
  }
  try {
    await transport.send(`kata-set-param maxTime ${rank.maxTimeSec}`)
  } catch {
    /* optional */
  }

  const resp = await transport.send(`genmove ${color}`)
  const move = parseGenmoveToken(resp)
  // genmove 가 실제 착수를 엔진 보드에 반영하므로 이력도 맞춤
  if (move === 'pass') {
    engineHistory.push({
      player: state.toPlay,
      x: -1,
      y: -1,
      pass: true,
      captured: [],
    })
  } else if (move) {
    engineHistory.push({
      player: state.toPlay,
      x: move.x,
      y: move.y,
      pass: false,
      captured: [],
    })
  }
  return move
}

export const KATAGO_SETUP_HINT = `
로컬 KataGo (HTTP 브리지) — NVIDIA GPU 권장
1) npm run katago:setup   (OpenCL; CUDA Toolkit 있으면 CUDA 빌드 선택)
2) npm run katago:bridge
3) 설정에서 「KataGo 브리지 연결」
RTX 5060 Ti: OpenCL이 GPU(Device 0)를 쓰는지 브리지 로그에서 확인.
`.trim()
