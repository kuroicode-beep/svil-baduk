// src/components/board/BoardGrid.tsx — 바둑판 접근성·입력 레이어
//
// SVG 위에 정확히 겹치는 DOM 격자. APG 의 grid 패턴을 따른다:
// 탭 가능한 노드는 격자 하나뿐이고, 현재 지점은 aria-activedescendant 로 가리킨다.
// (0.8.x 는 focusIdx 라는 React 상태만 있고 aria-activedescendant 가 없어서,
//  "선택됨" 라벨이 tabIndex=-1 인 SVG 원에 붙어 있었다. 스크린리더가 절대 닿지 못한다.)
//
// 히트 영역은 빈 점만이 아니라 모든 교차점에 깐다. 돌 위를 눌러도 침묵 대신
// "이미 돌이 있습니다" 안내가 나가고, 영역도 원이 아니라 셀 전체 사각형이라 넓다.

import type { GameState, Point } from '../../engine/types'
import { idx } from '../../engine/board'
import { cellPercent, columnLabel, pointToPercent, rowLabel, type BoardGeometry } from './geometry'

export interface CellLabels {
  empty: string
  black: string
  white: string
  lastMove: string
  selected: string
}

export interface BoardGridProps {
  state: GameState
  geometry: BoardGeometry
  gridId: string
  ariaLabel: string
  interactive: boolean
  cursor: Point
  armed: boolean
  lastMove: Point | null
  labels: CellLabels
  onCellActivate: (x: number, y: number) => void
  onKeyDown: (e: React.KeyboardEvent) => void
  onCursorMove: (p: Point) => void
}

export function cellId(gridId: string, x: number, y: number): string {
  return `${gridId}-c-${x}-${y}`
}

/** "D16 · 흑 · 직전 수" */
export function cellLabel(
  state: GameState,
  labels: CellLabels,
  lastMove: Point | null,
  x: number,
  y: number,
): string {
  const coord = `${columnLabel(x)}${rowLabel(y, state.size)}`
  const stone = state.board[idx(state.size, x, y)]
  const who = stone === 1 ? labels.black : stone === 2 ? labels.white : labels.empty
  const parts = [coord, who]
  if (lastMove && lastMove.x === x && lastMove.y === y) parts.push(labels.lastMove)
  return parts.join(' · ')
}

export function BoardGrid({
  state,
  geometry: g,
  gridId,
  ariaLabel,
  interactive,
  cursor,
  armed,
  lastMove,
  labels,
  onCellActivate,
  onKeyDown,
  onCursorMove,
}: BoardGridProps) {
  const size = state.size
  const cellSize = cellPercent(g)

  return (
    <div
      className="board-grid"
      role="grid"
      aria-label={ariaLabel}
      aria-rowcount={size}
      aria-colcount={size}
      aria-readonly={!interactive}
      aria-activedescendant={cellId(gridId, cursor.x, cursor.y)}
      tabIndex={0}
      onKeyDown={onKeyDown}
    >
      {Array.from({ length: size }, (_, y) => (
        <div className="board-row" role="row" aria-rowindex={y + 1} key={`row-${y}`}>
          {Array.from({ length: size }, (_, x) => {
            const { left, top } = pointToPercent(g, x, y)
            const isCursor = cursor.x === x && cursor.y === y
            return (
              <div
                key={`cell-${x}-${y}`}
                id={cellId(gridId, x, y)}
                role="gridcell"
                aria-colindex={x + 1}
                aria-selected={isCursor}
                aria-label={
                  cellLabel(state, labels, lastMove, x, y) +
                  (isCursor && armed ? ` · ${labels.selected}` : '')
                }
                className={`board-cell${isCursor ? ' board-cell--cursor' : ''}${
                  isCursor && armed ? ' board-cell--armed' : ''
                }`}
                style={{
                  left: `${left}%`,
                  top: `${top}%`,
                  width: `${cellSize}%`,
                  height: `${cellSize}%`,
                }}
                onClick={() => {
                  if (!interactive) return
                  onCursorMove({ x, y })
                  onCellActivate(x, y)
                }}
              />
            )
          })}
        </div>
      ))}
    </div>
  )
}
