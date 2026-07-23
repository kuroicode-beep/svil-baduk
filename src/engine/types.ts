export type Stone = 0 | 1 | 2 // empty | black | white
export type Player = 1 | 2
export type BoardSize = 9 | 13 | 19

export interface Point {
  x: number
  y: number
}

export interface Move {
  player: Player
  x: number
  y: number
  /** pass when x/y are -1 */
  pass?: boolean
  captured: Point[]
}

export interface GameState {
  size: BoardSize
  board: Stone[]
  toPlay: Player
  captures: Record<Player, number>
  history: Move[]
  koPoint: Point | null
  /** 위치 슈퍼코용 — 등장한 바둑판 해시 */
  positionHashes: string[]
  consecutivePasses: number
  ended: boolean
  /** 기권한 쪽 — 있으면 상대 승 */
  resignedBy: Player | null
}

export type PlayResult =
  | { ok: true; state: GameState; move: Move }
  | { ok: false; reason: string }
