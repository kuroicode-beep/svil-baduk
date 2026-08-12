// src/components/board/BoardSvg.tsx — 바둑판 시각 레이어
//
// 스크린리더에는 이 SVG 를 통째로 숨긴다. 접근성은 위에 겹치는
// BoardGrid(role="grid") 가 담당한다 — SVG 도형에 role="gridcell" 을 붙이는
// 방식은 NVDA·VoiceOver 지원이 고르지 않고, role="application" 은 저시력
// 사용자가 가장 필요로 하는 탐색 모드를 꺼버린다.

import { useMemo } from 'react'
import { idx, starPoints } from '../../engine/board'
import type { GameState, Point, Stone } from '../../engine/types'
import { blackStoneStyle, whiteStoneStyle, type BlackStoneId, type WhiteStoneId } from '../../settings/stoneColors'
import { BlinkOpacity, PulseRings } from '../PulseRings'
import { coordTicks, pointToXY, type BoardGeometry } from './geometry'

export interface BoardSvgProps {
  state: GameState
  geometry: BoardGeometry
  /** 착수 가능 지점 — 깜빡이는 안내점 */
  legal: Point[]
  interactive: boolean
  blink: boolean
  reduceMotion: boolean
  lastMove: Point | null
  blinkLastMove: boolean
  blackStone: BlackStoneId
  whiteStone: WhiteStoneId
  markers: Array<Point & { label?: string }>
  ownership?: Stone[]
  lineWidth: number
  /** 커서 위치 — 키보드 탐색 표시 */
  cursor: Point | null
  /** 착수 확정 대기 중 */
  armed: boolean
  blackLabel: string
  whiteLabel: string
  territoryBlackLabel: string
  territoryWhiteLabel: string
}

export function BoardSvg({
  state,
  geometry: g,
  legal,
  interactive,
  blink,
  reduceMotion,
  lastMove,
  blinkLastMove,
  blackStone,
  whiteStone,
  markers,
  ownership,
  lineWidth,
  cursor,
  armed,
  blackLabel,
  whiteLabel,
  territoryBlackLabel,
  territoryWhiteLabel,
}: BoardSvgProps) {
  const cell = g.cell
  const stoneR = cell * 0.42
  const stroke = Math.max(1, lineWidth)
  const starR = Math.max(8, cell * 0.18)
  const pulseThick = Math.max(5, cell * 0.11)
  /* 마커·글자 크기를 전부 셀 비례로 — 예전엔 12 처럼 고정이라
     판을 크게 할수록 상대적으로 작아 보이는 역효과가 났다 */
  const stoneFont = cell * 0.26
  const markerFont = cell * 0.3
  const coordFont = cell * 0.34
  const legalR = cell * 0.15
  const legalFocusR = cell * 0.21

  const stars = useMemo(() => starPoints(state.size), [state.size])
  const starSet = useMemo(() => new Set(stars.map((s) => `${s.x},${s.y}`)), [stars])
  const ticks = useMemo(() => coordTicks(g), [g])

  const blackStyle = blackStoneStyle(blackStone)
  const whiteStyle = whiteStoneStyle(whiteStone)
  const hintStyle = state.toPlay === 1 ? blackStyle : whiteStyle

  return (
    <svg
      className="board-svg"
      viewBox={`0 0 ${g.extent} ${g.extent}`}
      preserveAspectRatio="xMidYMid meet"
      aria-hidden="true"
      focusable="false"
    >
      <rect width={g.extent} height={g.extent} fill="var(--board-bg)" />
      <rect
        x={g.pad - cell * 0.5}
        y={g.pad - cell * 0.5}
        width={g.span + cell}
        height={g.span + cell}
        fill="var(--board-grid-bg)"
        stroke="var(--board-line)"
        strokeWidth={stroke + 1}
      />

      {Array.from({ length: state.size }, (_, i) => {
        const p = g.pad + i * cell
        return (
          <g key={`line-${i}`}>
            <line x1={g.pad} y1={p} x2={g.pad + g.span} y2={p} stroke="var(--board-line)" strokeWidth={stroke} />
            <line x1={p} y1={g.pad} x2={p} y2={g.pad + g.span} stroke="var(--board-line)" strokeWidth={stroke} />
          </g>
        )
      })}

      {/* 좌표 눈금 — 격자 바깥 4면. 낭독은 grid 셀 라벨이 담당하므로 시각 전용 */}
      {ticks.map((t, i) => (
        <text
          key={`tick-${i}`}
          x={t.cx}
          y={t.cy}
          textAnchor="middle"
          dominantBaseline="central"
          fill="var(--board-coord)"
          fontSize={coordFont}
          fontFamily="var(--font-mono)"
        >
          {t.label}
        </text>
      ))}

      {interactive &&
        legal.map((p) => {
          const { cx, cy } = pointToXY(g, p.x, p.y)
          const focused = cursor?.x === p.x && cursor?.y === p.y
          const onStar = starSet.has(`${p.x},${p.y}`)
          const cls = ['legal-dot', blink && !reduceMotion ? 'legal-dot--blink' : '', focused ? 'legal-dot--focus' : '']
            .join(' ')
            .trim()
          /* 화점 위에서는 링만 — 화점이 가려지지 않게 */
          return onStar ? (
            <circle
              key={`legal-${p.x}-${p.y}`}
              className={cls}
              cx={cx}
              cy={cy}
              r={starR + (focused ? 6 : 4)}
              fill="none"
              stroke="var(--board-legal)"
              strokeWidth={focused ? 4 : 3}
            />
          ) : (
            <circle
              key={`legal-${p.x}-${p.y}`}
              className={cls}
              cx={cx}
              cy={cy}
              r={focused ? legalFocusR : legalR}
              fill="var(--board-legal)"
              stroke="var(--board-star-stroke)"
              strokeWidth={2}
            />
          )
        })}

      {stars.map((s) => {
        const { cx, cy } = pointToXY(g, s.x, s.y)
        return (
          <circle
            key={`star-${s.x}-${s.y}`}
            cx={cx}
            cy={cy}
            r={starR}
            fill="var(--board-star-fill)"
            stroke="var(--board-star-stroke)"
            strokeWidth={Math.max(2, stroke)}
          />
        )
      })}

      {ownership?.map((owner, i) => {
        if (owner === 0 || state.board[i] !== 0) return null
        const x = i % state.size
        const y = Math.floor(i / state.size)
        const { cx, cy } = pointToXY(g, x, y)
        return (
          <g key={`own-${i}`}>
            <rect
              x={cx - cell * 0.35}
              y={cy - cell * 0.35}
              width={cell * 0.7}
              height={cell * 0.7}
              fill={owner === 1 ? 'var(--board-terr-black)' : 'var(--board-terr-white)'}
              stroke={owner === 1 ? 'var(--board-terr-black-line)' : 'var(--board-terr-white-line)'}
              strokeWidth={2}
            />
            <text
              x={cx}
              y={cy}
              textAnchor="middle"
              dominantBaseline="central"
              fill="var(--board-star-stroke)"
              fontSize={cell * 0.22}
              fontFamily="var(--font-mono)"
            >
              {owner === 1 ? territoryBlackLabel : territoryWhiteLabel}
            </text>
          </g>
        )
      })}

      {state.board.map((stone, i) => {
        if (stone === 0) return null
        const x = i % state.size
        const y = Math.floor(i / state.size)
        const { cx, cy } = pointToXY(g, x, y)
        const isLast = lastMove?.x === x && lastMove?.y === y
        const style = stone === 1 ? blackStyle : whiteStyle
        const blinkStone = Boolean(isLast && blinkLastMove && !reduceMotion)
        const body = (
          <>
            <circle cx={cx} cy={cy} r={stoneR} fill={style.fill} stroke={style.stroke} strokeWidth={3} />
            <text
              x={cx}
              y={cy}
              textAnchor="middle"
              dominantBaseline="central"
              fill={style.label}
              fontSize={stoneFont}
              fontFamily="var(--font-mono)"
            >
              {stone === 1 ? blackLabel : whiteLabel}
            </text>
          </>
        )
        return (
          <g key={`stone-${i}`}>
            {blinkStone ? <BlinkOpacity active periodMs={650}>{body}</BlinkOpacity> : body}
            {isLast && !blinkLastMove && (
              <circle cx={cx} cy={cy} r={stoneR * 0.28} fill="var(--board-lastmove)" stroke="var(--board-star-stroke)" strokeWidth={2} />
            )}
            {isLast && blinkLastMove && (
              <>
                <circle cx={cx} cy={cy} r={stoneR * 1.05} fill="none" stroke="var(--board-star-stroke)" strokeWidth={Math.max(3, cell * 0.06)} />
                <circle cx={cx} cy={cy} r={stoneR * 1.05} fill="none" stroke="var(--board-lastmove)" strokeWidth={Math.max(2.5, cell * 0.05)} />
                <PulseRings cx={cx} cy={cy} baseR={stoneR * 0.55} thick={pulseThick} color="var(--board-lastmove)" active={!reduceMotion} periodMs={1200} />
              </>
            )}
          </g>
        )
      })}

      {markers.map((p, mi) => {
        const { cx, cy } = pointToXY(g, p.x, p.y)
        const primary = mi === 0
        const ghost = (
          <circle
            cx={cx}
            cy={cy}
            r={stoneR}
            fill={hintStyle.fill}
            stroke={primary ? 'var(--board-hint)' : hintStyle.stroke}
            strokeWidth={primary ? 4 : 3}
            opacity={0.55}
          />
        )
        return (
          <g key={`mark-${p.x}-${p.y}`} pointerEvents="none">
            {reduceMotion ? ghost : <BlinkOpacity active periodMs={380}>{ghost}</BlinkOpacity>}
            <PulseRings cx={cx} cy={cy} baseR={stoneR * 0.55} thick={pulseThick} color="var(--board-hint)" active={!reduceMotion} periodMs={750} />
            {p.label && (
              <text
                x={cx}
                y={cy}
                textAnchor="middle"
                dominantBaseline="central"
                fill={primary ? 'var(--board-hint)' : hintStyle.label}
                fontSize={markerFont}
                fontFamily="var(--font-mono)"
                fontWeight={700}
              >
                {p.label}
              </text>
            )}
          </g>
        )
      })}

      {/* 착수 확정 대기 — 어디에 둘지 크고 분명하게 */}
      {armed && cursor && (
        <g pointerEvents="none">
          {(() => {
            const { cx, cy } = pointToXY(g, cursor.x, cursor.y)
            const occupied = state.board[idx(state.size, cursor.x, cursor.y)] !== 0
            return (
              <>
                <circle
                  cx={cx}
                  cy={cy}
                  r={stoneR * 1.25}
                  fill="none"
                  stroke="var(--focus)"
                  strokeWidth={Math.max(4, cell * 0.08)}
                />
                {!occupied && (
                  <circle cx={cx} cy={cy} r={stoneR} fill={hintStyle.fill} stroke={hintStyle.stroke} strokeWidth={3} opacity={0.5} />
                )}
              </>
            )
          })()}
        </g>
      )}
    </svg>
  )
}
