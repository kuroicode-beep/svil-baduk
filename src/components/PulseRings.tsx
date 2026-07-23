import { useEffect, useState, type ReactNode } from 'react'

/** CSS transform은 SVG에서 불안정 → r/opacity를 RAF로 직접 갱신 */
function usePhase(active: boolean, periodMs: number): number {
  const [t, setT] = useState(0)
  useEffect(() => {
    if (!active) {
      setT(0)
      return
    }
    let raf = 0
    const start = performance.now()
    const tick = (now: number) => {
      setT(((now - start) % periodMs) / periodMs)
      raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [active, periodMs])
  return t
}

export function BlinkOpacity({
  active,
  periodMs,
  children,
}: {
  active: boolean
  periodMs: number
  children: ReactNode
}) {
  const t = usePhase(active, periodMs)
  // 삼각파: 1 → 0.2 → 1
  const opacity = active ? 0.2 + 0.8 * (1 - Math.abs(2 * t - 1)) : 1
  return <g opacity={opacity}>{children}</g>
}

export function PulseRings({
  cx,
  cy,
  baseR,
  thick,
  color,
  active,
  periodMs = 1200,
  ringCount = 4,
}: {
  cx: number
  cy: number
  baseR: number
  thick: number
  color: string
  active: boolean
  periodMs?: number
  ringCount?: number
}) {
  const t = usePhase(active, periodMs)

  if (!active) {
    return (
      <g pointerEvents="none" aria-hidden>
        <circle cx={cx} cy={cy} r={baseR * 1.12} fill="none" stroke="#000" strokeWidth={thick + 5} />
        <circle cx={cx} cy={cy} r={baseR * 1.12} fill="none" stroke={color} strokeWidth={thick} />
      </g>
    )
  }

  return (
    <g pointerEvents="none" aria-hidden>
      {Array.from({ length: ringCount }, (_, i) => {
        const phase = (t + i / ringCount) % 1
        const r = baseR * (1 + phase * 2.2)
        const opacity = Math.max(0, 1 - phase)
        return (
          <g key={i} opacity={opacity}>
            <circle
              cx={cx}
              cy={cy}
              r={r}
              fill="none"
              stroke="#000000"
              strokeWidth={thick + 5}
              strokeLinecap="round"
            />
            <circle
              cx={cx}
              cy={cy}
              r={r}
              fill="none"
              stroke={color}
              strokeWidth={thick}
              strokeLinecap="round"
            />
          </g>
        )
      })}
    </g>
  )
}
