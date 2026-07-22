import { useEffect, useId, useMemo, useRef, useState } from 'react'
import { idx, legalMoves, starPoints } from '../engine/board'
import type { GameState, Point } from '../engine/types'

interface BoardProps {
  state: GameState
  interactive: boolean
  blink: boolean
  maxContrast: boolean
  reduceMotion: boolean
  lastMove: Point | null
  onPlay: (x: number, y: number) => void
  ariaLabel: string
}

export function Board({
  state,
  interactive,
  blink,
  maxContrast,
  reduceMotion,
  lastMove,
  onPlay,
  ariaLabel,
}: BoardProps) {
  const svgRef = useRef<SVGSVGElement>(null)
  const titleId = useId()
  const [focusIdx, setFocusIdx] = useState(0)
  const legal = useMemo(
    () => (interactive ? legalMoves(state) : []),
    [interactive, state],
  )
  const stars = useMemo(() => starPoints(state.size), [state.size])

  useEffect(() => {
    if (legal.length === 0) return
    setFocusIdx((i) => Math.min(i, legal.length - 1))
  }, [legal.length])

  const pad = 36
  const cell = 48
  const boardPx = pad * 2 + cell * (state.size - 1)
  const stoneR = cell * 0.42
  const line = maxContrast ? '#f5f5f7' : '#c9c9d4'
  const bg = maxContrast ? '#000000' : '#0d0d12'
  const gridBg = maxContrast ? '#111111' : '#16161d'

  const focusPoint = legal[focusIdx] ?? null

  function handleKey(e: React.KeyboardEvent) {
    if (!interactive || legal.length === 0) return
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      if (focusPoint) onPlay(focusPoint.x, focusPoint.y)
      return
    }
    if (!focusPoint) return
    const moveFocus = (nx: number, ny: number) => {
      let best = -1
      let bestDist = Infinity
      legal.forEach((p, i) => {
        const d = Math.abs(p.x - nx) + Math.abs(p.y - ny)
        if (d < bestDist) {
          bestDist = d
          best = i
        }
      })
      if (best >= 0) setFocusIdx(best)
    }
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      moveFocus(focusPoint.x + 1, focusPoint.y)
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      moveFocus(focusPoint.x - 1, focusPoint.y)
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      moveFocus(focusPoint.x, focusPoint.y + 1)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      moveFocus(focusPoint.x, focusPoint.y - 1)
    } else if (e.key === 'Tab') {
      e.preventDefault()
      setFocusIdx((i) => (e.shiftKey ? (i - 1 + legal.length) % legal.length : (i + 1) % legal.length))
    } else if (e.key === 'Home') {
      e.preventDefault()
      setFocusIdx(0)
    } else if (e.key === 'End') {
      e.preventDefault()
      setFocusIdx(legal.length - 1)
    }
  }

  return (
    <div className="board-wrap">
      <svg
        ref={svgRef}
        className="board-svg"
        width={boardPx}
        height={boardPx}
        viewBox={`0 0 ${boardPx} ${boardPx}`}
        role="application"
        aria-labelledby={titleId}
        aria-label={ariaLabel}
        tabIndex={interactive ? 0 : -1}
        onKeyDown={handleKey}
      >
        <title id={titleId}>{ariaLabel}</title>
        <rect width={boardPx} height={boardPx} fill={bg} />
        <rect
          x={pad - cell * 0.5}
          y={pad - cell * 0.5}
          width={cell * (state.size - 1) + cell}
          height={cell * (state.size - 1) + cell}
          fill={gridBg}
          stroke={line}
          strokeWidth={3}
        />
        {Array.from({ length: state.size }, (_, i) => {
          const p = pad + i * cell
          return (
            <g key={`line-${i}`}>
              <line x1={pad} y1={p} x2={pad + cell * (state.size - 1)} y2={p} stroke={line} strokeWidth={2} />
              <line x1={p} y1={pad} x2={p} y2={pad + cell * (state.size - 1)} stroke={line} strokeWidth={2} />
            </g>
          )
        })}
        {stars.map((s) => (
          <circle
            key={`star-${s.x}-${s.y}`}
            cx={pad + s.x * cell}
            cy={pad + s.y * cell}
            r={5}
            fill={line}
          />
        ))}
        {interactive &&
          legal.map((p) => {
            const cx = pad + p.x * cell
            const cy = pad + p.y * cell
            const focused = focusPoint?.x === p.x && focusPoint?.y === p.y
            return (
              <circle
                key={`legal-${p.x}-${p.y}`}
                className={[
                  'legal-dot',
                  blink && !reduceMotion ? 'legal-dot--blink' : '',
                  focused ? 'legal-dot--focus' : '',
                ].join(' ')}
                cx={cx}
                cy={cy}
                r={focused ? 10 : 7}
                fill="#ffd479"
                stroke="#000"
                strokeWidth={2}
                onClick={() => onPlay(p.x, p.y)}
                role="button"
                aria-label={`착수 ${p.x + 1},${p.y + 1}${focused ? ' 선택됨' : ''}`}
                tabIndex={-1}
              />
            )
          })}
        {state.board.map((stone, i) => {
          if (stone === 0) return null
          const x = i % state.size
          const y = Math.floor(i / state.size)
          const cx = pad + x * cell
          const cy = pad + y * cell
          const isLast = lastMove && lastMove.x === x && lastMove.y === y
          const fill = stone === 1 ? '#f5f5f7' : '#1a1a1a'
          const stroke = stone === 1 ? '#000000' : '#f5f5f7'
          return (
            <g key={`stone-${i}`}>
              <circle cx={cx} cy={cy} r={stoneR} fill={fill} stroke={stroke} strokeWidth={3} />
              {stone === 2 && (
                <text
                  x={cx}
                  y={cy + 5}
                  textAnchor="middle"
                  fill="#f5f5f7"
                  fontSize={12}
                  fontFamily="Consolas, monospace"
                  aria-hidden
                >
                  백
                </text>
              )}
              {stone === 1 && (
                <text
                  x={cx}
                  y={cy + 5}
                  textAnchor="middle"
                  fill="#000000"
                  fontSize={12}
                  fontFamily="Consolas, monospace"
                  aria-hidden
                >
                  흑
                </text>
              )}
              {isLast && (
                <circle
                  cx={cx}
                  cy={cy}
                  r={stoneR * 0.28}
                  fill="#ffd479"
                  stroke="#000"
                  strokeWidth={2}
                />
              )}
            </g>
          )
        })}
        {/* invisible hit targets for empty points */}
        {interactive &&
          Array.from({ length: state.size * state.size }, (_, i) => {
            const x = i % state.size
            const y = Math.floor(i / state.size)
            if (state.board[idx(state.size, x, y)] !== 0) return null
            return (
              <circle
                key={`hit-${i}`}
                cx={pad + x * cell}
                cy={pad + y * cell}
                r={cell * 0.4}
                fill="transparent"
                className="hit-target"
                onClick={() => onPlay(x, y)}
              />
            )
          })}
      </svg>
    </div>
  )
}
