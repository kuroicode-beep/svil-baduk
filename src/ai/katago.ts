/**
 * KataGo GTP 클라이언트.
 * 브라우저 → 로컬 HTTP 브리지(scripts/katago-bridge.mjs) → katago.exe stdin/stdout
 */

import type { GameState, Point } from '../engine/types'
import { pointLabel } from '../engine/board'
import { getRank, type RankId } from './ranks'
import { parseGenmoveToken } from './gtpParse'

export type KataGoTransport = {
  send: (line: string) => Promise<string>
  isConnected: () => boolean
}

let transport: KataGoTransport | null = null

export function setKataGoTransport(t: KataGoTransport | null) {
  transport = t
}

export function isKataGoAvailable(): boolean {
  return !!transport?.isConnected()
}

function gtpCoord(x: number, y: number): string {
  return pointLabel(x, y)
}

export async function katagoGenmove(
  state: GameState,
  rankId: RankId,
): Promise<Point | 'pass' | null> {
  if (!transport?.isConnected()) return null
  const rank = getRank(rankId)
  const color = state.toPlay === 1 ? 'B' : 'W'
  await transport.send(`boardsize ${state.size}`)
  await transport.send('clear_board')
  // visits 힌트 (엔진/버전에 따라 무시될 수 있음)
  try {
    await transport.send(`kata-set-param maxVisits ${rank.visits}`)
  } catch {
    /* optional */
  }
  for (const m of state.history) {
    if (m.pass) {
      await transport.send(`play ${m.player === 1 ? 'B' : 'W'} pass`)
    } else {
      await transport.send(`play ${m.player === 1 ? 'B' : 'W'} ${gtpCoord(m.x, m.y)}`)
    }
  }
  const resp = await transport.send(`genmove ${color}`)
  return parseGenmoveToken(resp)
}

export const KATAGO_SETUP_HINT = `
로컬 KataGo (HTTP 브리지)
1) https://github.com/lightvector/KataGo/releases 에서 바이너리 다운로드 → katago/bin/katago.exe
2) 네트워크 모델(.bin.gz) → katago/models/
3) 터미널: npm run katago:bridge
4) 앱 설정에서 「KataGo 브리지 연결」
`.trim()
