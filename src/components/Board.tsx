import { useEffect, useId, useMemo, useRef, useState } from 'react'
import { idx, legalMoves, starPoints } from '../engine/board'
import type { GameState, Point, Stone } from '../engine/types'
import {
  blackStoneStyle,
  whiteStoneStyle,
  type BlackStoneId,
  type WhiteStoneId,
} from '../settings/stoneColors'

interface BoardProps {
  state: GameState
  interactive: boolean
  blink: boolean
  maxContrast: boolean
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
  cellSize?: number
  lineWidth?: number
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
  blinkLastMove = false,
  blackStone = 'black',
  whiteStone = 'white',
  markers = [],
  ownership,
  cellSize = 48,
  lineWidth = 2.5,
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
  const starSet = useMemo(
    () => new Set(stars.map((s) => `${s.x},${s.y}`)),
    [stars],
  )

  useEffect(() => {
    if (legal.length === 0) return
    setFocusIdx((i) => Math.min(i, legal.length - 1))
  }, [legal.length])

  const pad = Math.round(cellSize * 0.75)
  const cell = cellSize
  const boardPx = pad * 2 + cell * (state.size - 1)
  const stoneR = cell * 0.42
  const stroke = Math.max(1, lineWidth)
  /** 화점: 칸 비율 + 최소 크기 — 저시력에서도 격자선과 구분 */
  const starR = Math.max(8, cell * 0.18)
  const line = maxContrast ? '#f5f5f7' : '#c9c9d4'
  const starFill = '#ffffff'
  const starStroke = '#000000'
  const bg = maxContrast ? '#000000' : '#0d0d12'
  const gridBg = maxContrast ? '#111111' : '#16161d'

  const blackStyle = blackStoneStyle(blackStone)
  const whiteStyle = whiteStoneStyle(whiteStone)
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
        viewBox={`0 0 ${boardPx} ${boardPx}`}
        preserveAspectRatio="xMidYMid meet"
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
          strokeWidth={stroke + 1}
        />
        {Array.from({ length: state.size }, (_, i) => {
          const p = pad + i * cell
          return (
            <g key={`line-${i}`}>
              <line x1={pad} y1={p} x2={pad + cell * (state.size - 1)} y2={p} stroke={line} strokeWidth={stroke} />
              <line x1={p} y1={pad} x2={p} y2={pad + cell * (state.size - 1)} stroke={line} strokeWidth={stroke} />
            </g>
          )
        })}
        {interactive &&
          legal.map((p) => {
            const cx = pad + p.x * cell
            const cy = pad + p.y * cell
            const focused = focusPoint?.x === p.x && focusPoint?.y === p.y
            const onStar = starSet.has(`${p.x},${p.y}`)
            /* 화점 위에서는 링만 — 화점 점이 가려지지 않게 */
            if (onStar) {
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
                  r={starR + (focused ? 6 : 4)}
                  fill="none"
                  stroke="#ffd479"
                  strokeWidth={focused ? 4 : 3}
                  onClick={() => onPlay(p.x, p.y)}
                  role="button"
                  aria-label={`착수 ${p.x + 1},${p.y + 1}${focused ? ' 선택됨' : ''}`}
                  tabIndex={-1}
                />
              )
            }
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
        {stars.map((s) => (
          <circle
            key={`star-${s.x}-${s.y}`}
            className="board-hoshi"
            cx={pad + s.x * cell}
            cy={pad + s.y * cell}
            r={starR}
            fill={starFill}
            stroke={starStroke}
            strokeWidth={Math.max(2, stroke)}
            aria-hidden
          />
        ))}
        {ownership &&
          ownership.map((owner, i) => {
            if (owner === 0 || state.board[i] !== 0) return null
            const x = i % state.size
            const y = Math.floor(i / state.size)
            const cx = pad + x * cell
            const cy = pad + y * cell
            const fill = owner === 1 ? 'rgba(179,221,255,0.55)' : 'rgba(255,155,155,0.5)'
            const label = owner === 1 ? '흑집' : '백집'
            return (
              <g key={`own-${i}`}>
                <rect
                  x={cx - cell * 0.35}
                  y={cy - cell * 0.35}
                  width={cell * 0.7}
                  height={cell * 0.7}
                  fill={fill}
                  stroke={owner === 1 ? '#b3ddff' : '#ff9b9b'}
                  strokeWidth={2}
                />
                <text
                  x={cx}
                  y={cy + 4}
                  textAnchor="middle"
                  fill={owner === 1 ? '#000' : '#000'}
                  fontSize={Math.max(10, cell * 0.22)}
                  fontFamily="Consolas, monospace"
                >
                  {label}
                </text>
              </g>
            )
          })}
        {state.board.map((stone, i) => {
          if (stone === 0) return null
          const x = i % state.size
          const y = Math.floor(i / state.size)
          const cx = pad + x * cell
          const cy = pad + y * cell
          const isLast = lastMove && lastMove.x === x && lastMove.y === y
          const style = stone === 1 ? blackStyle : whiteStyle
          const label = stone === 1 ? '흑' : '백'
          return (
            <g key={`stone-${i}`}>
              <circle
                cx={cx}
                cy={cy}
                r={stoneR}
                fill={style.fill}
                stroke={style.stroke}
                strokeWidth={3}
              />
              <text
                x={cx}
                y={cy + 5}
                textAnchor="middle"
                fill={style.label}
                fontSize={12}
                fontFamily="Consolas, monospace"
                aria-hidden
              >
                {label}
              </text>
              {isLast && (
                <circle
                  className={[
                    'last-move-mark',
                    blinkLastMove && !reduceMotion ? 'last-move-mark--blink' : '',
                  ].join(' ')}
                  cx={cx}
                  cy={cy}
                  r={stoneR * (blinkLastMove ? 0.38 : 0.28)}
                  fill="#ffd479"
                  stroke="#000"
                  strokeWidth={blinkLastMove ? 3 : 2}
                />
              )}
            </g>
          )
        })}
        {markers.map((p) => (
          <g key={`mark-${p.x}-${p.y}`}>
            <circle
              cx={pad + p.x * cell}
              cy={pad + p.y * cell}
              r={14}
              fill="rgba(0,0,0,0.65)"
              stroke="#7ee2a8"
              strokeWidth={3}
            />
            <text
              x={pad + p.x * cell}
              y={pad + p.y * cell + 5}
              textAnchor="middle"
              fill="#7ee2a8"
              fontSize={p.label && p.label.length > 3 ? 10 : 12}
              fontFamily="Consolas, monospace"
              fontWeight={700}
            >
              {p.label ?? (markers.length === 1 ? '힌트' : '정답')}
            </text>
          </g>
        ))}
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
