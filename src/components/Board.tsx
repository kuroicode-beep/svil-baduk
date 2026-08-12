// src/components/Board.tsx — 시각(BoardSvg) + 접근성·입력(BoardGrid) 합성
import { useEffect, useId, useMemo, useState } from 'react'
import { idx, legalMoves } from '../engine/board'
import type { GameState, Point, Stone } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import type { BlackStoneId, WhiteStoneId } from '../settings/stoneColors'
import { BoardGrid, type CellLabels } from './board/BoardGrid'
import { BoardSvg } from './board/BoardSvg'
import { boardGeometry, columnLabel, rowLabel, stepCursor } from './board/geometry'
import { defaultPlaceMode, shouldShowCoords, useBoardFit } from './board/useBoardFit'

/** 'direct' 는 누르면 바로 착수, 'confirm' 은 고른 뒤 확정 버튼 */
export type PlaceMode = 'direct' | 'confirm'

interface BoardProps {
  state: GameState
  lang: Lang
  interactive: boolean
  blink: boolean
  reduceMotion: boolean
  lastMove: Point | null
  /** 상대 직전 수 — 내 착수 전까지 깜빡임 */
  blinkLastMove?: boolean
  blackStone?: BlackStoneId
  whiteStone?: WhiteStoneId
  /** 힌트/분석 후보 — label이 있으면 숫자·퍼센트 표시 */
  markers?: Array<Point & { label?: string }>
  /** 계가 소유권: 1흑집 2백집 0공배 */
  ownership?: Stone[]
  /** 좌표 눈금 — 'auto' 는 칸이 작아지면 자동으로 숨긴다 */
  coordMode?: 'auto' | 'on' | 'off'
  /** 생략하면 판 크기·입력 기기에 따라 자동 */
  placeMode?: PlaceMode
  lineWidth?: number
  onPlay: (x: number, y: number) => void
  ariaLabel: string
}

export function Board({
  state,
  lang,
  interactive,
  blink,
  reduceMotion,
  lastMove,
  blinkLastMove = false,
  blackStone = 'black',
  whiteStone = 'white',
  markers = [],
  ownership,
  coordMode = 'auto',
  placeMode,
  lineWidth = 2.5,
  onPlay,
  ariaLabel,
}: BoardProps) {
  const gridId = useId()
  const { ref: fitRef, cellPx } = useBoardFit(state.size)
  const showCoords = shouldShowCoords(coordMode, cellPx)
  const mode: PlaceMode = placeMode ?? defaultPlaceMode(state.size)
  const [cursor, setCursor] = useState<Point>(() => ({
    x: Math.floor(state.size / 2),
    y: Math.floor(state.size / 2),
  }))
  const [armed, setArmed] = useState(false)

  const geometry = useMemo(() => boardGeometry(state.size, showCoords), [state.size, showCoords])
  const legal = useMemo(() => (interactive ? legalMoves(state) : []), [interactive, state])

  // 판이 바뀌면 커서를 범위 안으로, 확정 대기는 해제
  useEffect(() => {
    setCursor((c) => ({
      x: Math.min(c.x, state.size - 1),
      y: Math.min(c.y, state.size - 1),
    }))
    setArmed(false)
  }, [state.size])

  useEffect(() => {
    setArmed(false)
  }, [state.history.length, interactive])

  const labels: CellLabels = {
    empty: t(lang, 'pointEmpty'),
    black: t(lang, 'black'),
    white: t(lang, 'white'),
    lastMove: t(lang, 'lastMove'),
    selected: t(lang, 'selectedPoint'),
  }

  /** 확정 모드에서는 같은 지점을 두 번 눌러야 착수된다 */
  function activate(x: number, y: number) {
    if (!interactive) return
    if (mode === 'direct') {
      onPlay(x, y)
      return
    }
    const same = armed && cursor.x === x && cursor.y === y
    if (same) {
      setArmed(false)
      onPlay(x, y)
    } else {
      setArmed(true)
    }
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (!interactive) return
    const move = (dx: number, dy: number) => {
      e.preventDefault()
      setCursor((c) => stepCursor(c, dx, dy, state.size))
      setArmed(false)
    }
    switch (e.key) {
      case 'ArrowRight': return move(1, 0)
      case 'ArrowLeft': return move(-1, 0)
      case 'ArrowDown': return move(0, 1)
      case 'ArrowUp': return move(0, -1)
      case 'PageUp': return move(0, -5)
      case 'PageDown': return move(0, 5)
      case 'Home':
        e.preventDefault()
        setCursor((c) => ({ x: 0, y: c.y }))
        setArmed(false)
        return
      case 'End':
        e.preventDefault()
        setCursor((c) => ({ x: state.size - 1, y: c.y }))
        setArmed(false)
        return
      case 'Escape':
        if (armed) {
          e.preventDefault()
          setArmed(false)
        }
        return
      case 'Enter':
      case ' ':
        e.preventDefault()
        activate(cursor.x, cursor.y)
        return
      default:
    }
  }

  const cursorOccupied = state.board[idx(state.size, cursor.x, cursor.y)] !== 0
  const cursorCoord = `${columnLabel(cursor.x)}${rowLabel(cursor.y, state.size)}`

  return (
    <div className="board-wrap">
      <div className="board-fit" ref={fitRef}>
        <BoardSvg
          state={state}
          geometry={geometry}
          legal={legal}
          interactive={interactive}
          blink={blink}
          reduceMotion={reduceMotion}
          lastMove={lastMove}
          blinkLastMove={blinkLastMove}
          blackStone={blackStone}
          whiteStone={whiteStone}
          markers={markers}
          ownership={ownership}
          lineWidth={lineWidth}
          cursor={interactive ? cursor : null}
          armed={armed}
          blackLabel={t(lang, 'black')}
          whiteLabel={t(lang, 'white')}
          territoryBlackLabel={t(lang, 'territoryBlack')}
          territoryWhiteLabel={t(lang, 'territoryWhite')}
        />
        <BoardGrid
          state={state}
          geometry={geometry}
          gridId={gridId}
          ariaLabel={ariaLabel}
          interactive={interactive}
          cursor={cursor}
          armed={armed}
          lastMove={lastMove}
          labels={labels}
          onCellActivate={activate}
          onCursorMove={setCursor}
          onKeyDown={handleKeyDown}
        />
      </div>

      {/* 확정 모드: 실제로 커밋하는 타깃은 크게 만든다.
          19줄에서 교차점 자체를 50px 로 만드는 건 산술적으로 불가능하다. */}
      {interactive && mode === 'confirm' && (
        <div className="board-confirm">
          <button
            type="button"
            className="btn btn-primary board-confirm-btn"
            disabled={!armed || cursorOccupied}
            onClick={() => {
              setArmed(false)
              onPlay(cursor.x, cursor.y)
            }}
          >
            {t(lang, 'confirmPlace')} ({cursorCoord})
          </button>
        </div>
      )}
    </div>
  )
}
