// src/components/board/geometry.ts — 바둑판 좌표계
//
// 셀 크기는 viewBox 안에서 항상 48 단위로 고정한다.
// (예전에는 설정의 boardScale 이 viewBox 셀 크기를 바꿨는데, SVG 는 어차피
//  컨테이너를 채우므로 화면상 판 크기는 그대로였고, 대신 user unit 이 고정인
//  돌 글자·힌트 점만 상대적으로 작아지는 역효과가 났다.)
// 판을 키우는 일은 CSS(--board-max)가 맡는다.

import type { BoardSize, Point } from '../../engine/types'

export const CELL_UNITS = 48
/** 마지막 줄 바깥 여백 — 돌이 잘리지 않을 만큼 */
export const EDGE_UNITS = 24
/** 좌표 눈금이 들어갈 자리 */
export const GUTTER_UNITS = 40

export interface BoardGeometry {
  size: number
  cell: number
  /** 좌표를 그릴 때만 0 보다 크다 */
  gutter: number
  /** viewBox 원점에서 첫 줄까지 */
  pad: number
  /** 첫 줄에서 마지막 줄까지 */
  span: number
  /** viewBox 한 변 */
  extent: number
}

export function boardGeometry(size: BoardSize, coords: boolean): BoardGeometry {
  const gutter = coords ? GUTTER_UNITS : 0
  const pad = gutter + EDGE_UNITS
  const span = CELL_UNITS * (size - 1)
  return { size, cell: CELL_UNITS, gutter, pad, span, extent: pad * 2 + span }
}

export function pointToXY(g: BoardGeometry, x: number, y: number): { cx: number; cy: number } {
  return { cx: g.pad + x * g.cell, cy: g.pad + y * g.cell }
}

/** 컨테이너 대비 백분율 — DOM 오버레이를 SVG 와 정확히 겹치게 한다 */
export function pointToPercent(
  g: BoardGeometry,
  x: number,
  y: number,
): { left: number; top: number } {
  const { cx, cy } = pointToXY(g, x, y)
  return { left: (cx / g.extent) * 100, top: (cy / g.extent) * 100 }
}

export function cellPercent(g: BoardGeometry): number {
  return (g.cell / g.extent) * 100
}

const COLUMN_LETTERS = 'ABCDEFGHJKLMNOPQRST'

/** 열 이름 — I 를 건너뛴다 */
export function columnLabel(x: number): string {
  return COLUMN_LETTERS[x] ?? '?'
}

/** 행 번호 — board 배열은 y=0 이 위쪽이고 표준 표기는 아래가 1 */
export function rowLabel(y: number, size: number): number {
  return size - y
}

/** 4면 좌표 눈금 위치 */
export interface CoordTick {
  label: string
  cx: number
  cy: number
  axis: 'column' | 'row'
  side: 'start' | 'end'
}

export function coordTicks(g: BoardGeometry): CoordTick[] {
  if (g.gutter === 0) return []
  const ticks: CoordTick[] = []
  const near = g.pad - g.gutter * 0.5
  const far = g.pad + g.span + g.gutter * 0.5

  for (let x = 0; x < g.size; x++) {
    const { cx } = pointToXY(g, x, 0)
    const label = columnLabel(x)
    ticks.push({ label, cx, cy: near, axis: 'column', side: 'start' })
    ticks.push({ label, cx, cy: far, axis: 'column', side: 'end' })
  }
  for (let y = 0; y < g.size; y++) {
    const { cy } = pointToXY(g, 0, y)
    const label = String(rowLabel(y, g.size))
    ticks.push({ label, cx: near, cy, axis: 'row', side: 'start' })
    ticks.push({ label, cx: far, cy, axis: 'row', side: 'end' })
  }
  return ticks
}

/** 화살표 이동 — 합법 지점으로 점프하지 않고 기하학적으로 한 칸 */
export function stepCursor(p: Point, dx: number, dy: number, size: number): Point {
  return {
    x: Math.min(size - 1, Math.max(0, p.x + dx)),
    y: Math.min(size - 1, Math.max(0, p.y + dy)),
  }
}
