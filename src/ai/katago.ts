/**
 * KataGo GTP 클라이언트 (데스크톱/사이드카용).
 * 브라우저 MVP에서는 연결 불가 → builtin AI로 폴백.
 * Tauri/Electron에서 spawn한 GTP stdin/stdout과 연결한다.
 */

import type { GameState, Point } from '../engine/types'
import { pointLabel } from '../engine/board'
import { getRank, type RankId } from './ranks'

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
  // 보드 재동기화 (간단 버전: clear + play history)
  await transport.send(`boardsize ${state.size}`)
  await transport.send('clear_board')
  await transport.send(`kata-set-param playoutDoublingAdvantage 0`)
  // visits는 analysis 엔진에서 쓰는 경우가 많아 genmove 전 힌트만
  void rank.visits
  for (const m of state.history) {
    if (m.pass) {
      await transport.send(`play ${m.player === 1 ? 'B' : 'W'} pass`)
    } else {
      await transport.send(`play ${m.player === 1 ? 'B' : 'W'} ${gtpCoord(m.x, m.y)}`)
    }
  }
  const resp = await transport.send(`genmove ${color}`)
  const token = resp.trim().split(/\s+/).pop()?.toUpperCase()
  if (!token || token === 'PASS' || token === 'RESIGN') return 'pass'
  const letters = 'ABCDEFGHJKLMNOPQRST'
  const col = letters.indexOf(token[0])
  const row = Number(token.slice(1)) - 1
  if (col < 0 || Number.isNaN(row)) return null
  return { x: col, y: row }
}

export const KATAGO_SETUP_HINT = `
로컬 KataGo 사용법 (예정: Tauri 사이드카)
1) https://github.com/lightvector/KataGo/releases 에서 바이너리 다운로드
2) 네트워크 모델(.bin.gz)을 katago/models/ 에 배치
3) katago/bin/katago.exe gtp -model ... -config ...
4) 앱 설정에서 GTP 경로 연결
`.trim()
