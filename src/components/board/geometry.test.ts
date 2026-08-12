// src/components/board/geometry.test.ts
import { describe, expect, it } from 'vitest'
import { pointLabel } from '../../engine/board'
import {
  boardGeometry,
  CELL_UNITS,
  cellPercent,
  columnLabel,
  coordTicks,
  pointToPercent,
  pointToXY,
  rowLabel,
  stepCursor,
} from './geometry'

describe('boardGeometry', () => {
  it('셀 크기는 판 크기·좌표 표시와 무관하게 고정', () => {
    for (const size of [9, 13, 19] as const) {
      for (const coords of [true, false]) {
        expect(boardGeometry(size, coords).cell).toBe(CELL_UNITS)
      }
    }
  })

  it('좌표를 켜면 거터만큼 넓어진다', () => {
    const off = boardGeometry(19, false)
    const on = boardGeometry(19, true)
    expect(on.extent).toBeGreaterThan(off.extent)
    // 19줄에서 약 8.8% 증가 — 판 자체가 줄어들지 않게 감수할 만한 수준
    expect(on.extent / off.extent).toBeLessThan(1.1)
  })

  it('첫 줄과 마지막 줄이 대칭으로 놓인다', () => {
    const g = boardGeometry(13, true)
    const first = pointToXY(g, 0, 0)
    const last = pointToXY(g, 12, 12)
    expect(first.cx).toBe(g.pad)
    expect(g.extent - last.cx).toBe(g.pad)
  })

  it('백분율 변환이 SVG 좌표와 일치한다 — 오버레이 정렬의 근거', () => {
    const g = boardGeometry(9, true)
    for (const [x, y] of [[0, 0], [4, 4], [8, 8], [2, 6]] as const) {
      const { cx, cy } = pointToXY(g, x, y)
      const { left, top } = pointToPercent(g, x, y)
      expect(left).toBeCloseTo((cx / g.extent) * 100, 10)
      expect(top).toBeCloseTo((cy / g.extent) * 100, 10)
    }
    expect(cellPercent(g)).toBeCloseTo((CELL_UNITS / g.extent) * 100, 10)
  })
})

describe('좌표 라벨', () => {
  it('열은 I 를 건너뛴다', () => {
    expect(columnLabel(0)).toBe('A')
    expect(columnLabel(7)).toBe('H')
    expect(columnLabel(8)).toBe('J')
    expect(columnLabel(18)).toBe('T')
  })

  it('행은 아래가 1', () => {
    expect(rowLabel(0, 19)).toBe(19)
    expect(rowLabel(18, 19)).toBe(1)
    expect(rowLabel(4, 9)).toBe(5)
  })

  it('pointLabel 과 정확히 같은 문자열을 만든다', () => {
    for (const size of [9, 13, 19] as const) {
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          expect(`${columnLabel(x)}${rowLabel(y, size)}`).toBe(pointLabel(x, y, size))
        }
      }
    }
  })
})

describe('coordTicks', () => {
  it('좌표를 끄면 눈금이 없다', () => {
    expect(coordTicks(boardGeometry(19, false))).toEqual([])
  })

  it('4면 전부 — 줄 수 × 2축 × 2면', () => {
    const ticks = coordTicks(boardGeometry(9, true))
    expect(ticks).toHaveLength(9 * 4)
    expect(ticks.filter((t) => t.axis === 'column')).toHaveLength(18)
    expect(ticks.filter((t) => t.side === 'end')).toHaveLength(18)
  })

  it('눈금은 격자 바깥에 놓인다', () => {
    const g = boardGeometry(9, true)
    for (const t of coordTicks(g)) {
      const outside =
        t.cx < g.pad || t.cx > g.pad + g.span || t.cy < g.pad || t.cy > g.pad + g.span
      expect(outside).toBe(true)
    }
  })

  it('좌상단 행 눈금이 19줄에서 19', () => {
    const ticks = coordTicks(boardGeometry(19, true))
    const topRow = ticks.find((t) => t.axis === 'row' && t.side === 'start' && t.cy === boardGeometry(19, true).pad)
    expect(topRow?.label).toBe('19')
  })
})

describe('stepCursor', () => {
  it('한 칸씩 기하학적으로 움직인다', () => {
    expect(stepCursor({ x: 3, y: 3 }, 1, 0, 9)).toEqual({ x: 4, y: 3 })
    expect(stepCursor({ x: 3, y: 3 }, 0, -1, 9)).toEqual({ x: 3, y: 2 })
  })

  it('가장자리에서 멈춘다 — 반대편으로 순간이동하지 않는다', () => {
    expect(stepCursor({ x: 0, y: 0 }, -1, 0, 9)).toEqual({ x: 0, y: 0 })
    expect(stepCursor({ x: 8, y: 8 }, 1, 1, 9)).toEqual({ x: 8, y: 8 })
  })
})
