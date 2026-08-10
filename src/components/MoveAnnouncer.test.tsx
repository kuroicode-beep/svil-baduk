// src/components/MoveAnnouncer.test.tsx
import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { createGame, tryPlay } from '../engine/board'
import type { GameState } from '../engine/types'
import { MoveAnnouncer } from './MoveAnnouncer'

/** 좌표 목록을 순서대로 둔 상태 */
function play(size: 9 | 13 | 19, moves: [number, number][]): GameState {
  let g = createGame(size)
  for (const [x, y] of moves) {
    const r = tryPlay(g, x, y)
    if (!r.ok) throw new Error(`illegal ${x},${y}: ${r.reason}`)
    g = r.state
  }
  return g
}

describe('MoveAnnouncer', () => {
  it('announces the standard Go coordinate, counting rows from the bottom', () => {
    // board 배열의 (3,3)은 좌상귀 화점 → 표준 표기로 D16 (예전엔 D4로 잘못 읽었다)
    const g = play(19, [[3, 3]])
    render(<MoveAnnouncer lang="ko" state={g} />)
    const live = screen.getByText(/D16/)
    expect(live).toBeInTheDocument()
    expect(live).toHaveTextContent('흑')
    expect(live.textContent).not.toMatch(/D4\b/)
  })

  it('uses a polite atomic live region so the whole move is read as one unit', () => {
    const g = play(9, [[4, 4]])
    render(<MoveAnnouncer lang="ko" state={g} />)
    const live = screen.getByText(/E5/)
    expect(live).toHaveAttribute('aria-live', 'polite')
    expect(live).toHaveAttribute('aria-atomic', 'true')
    expect(live).toHaveClass('sr-only')
  })

  it('reports captures alongside the coordinate', () => {
    // 흑이 (0,0) 백을 따냄
    const g = play(9, [
      [1, 0], // B
      [0, 0], // W
      [0, 1], // B — (0,0) 백은 활로 0 → 따냄
    ])
    expect(g.history[g.history.length - 1].captured).toHaveLength(1)
    render(<MoveAnnouncer lang="ko" state={g} />)
    const live = screen.getByText(/A8/)
    expect(live.textContent).toMatch(/1/)
  })

  it('falls back to a turn prompt on an empty board', () => {
    render(<MoveAnnouncer lang="ko" state={createGame(9)} />)
    expect(screen.getByText(/차례/)).toBeInTheDocument()
  })
})
