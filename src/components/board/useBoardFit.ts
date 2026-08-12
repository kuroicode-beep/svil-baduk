// src/components/board/useBoardFit.ts — 실측 칸 크기에 따른 자동 조정
import { useEffect, useRef, useState } from 'react'
import type { BoardSize } from '../../engine/types'

/** 이보다 칸이 작아지면 좌표 글자가 읽히지 않는다 */
const MIN_COORD_CELL_PX = 22

export interface BoardFit {
  ref: React.RefObject<HTMLDivElement | null>
  /** 실측 한 칸 크기(CSS px) — 설정 화면 안내에도 쓴다 */
  cellPx: number
}

/**
 * 컨테이너 폭을 재서 한 칸이 몇 px 인지 계산한다.
 * 'auto' 좌표 모드에서 눈금을 숨길지 판단하는 근거.
 */
export function useBoardFit(size: BoardSize): BoardFit {
  const ref = useRef<HTMLDivElement | null>(null)
  const [cellPx, setCellPx] = useState(0)

  useEffect(() => {
    const el = ref.current
    if (!el || typeof ResizeObserver === 'undefined') return
    const ro = new ResizeObserver((entries) => {
      const box = entries[0]?.contentRect
      if (!box) return
      const side = Math.min(box.width, box.height)
      // 판 양쪽 여백을 뺀 대략치 — 눈금 표시 여부 판단에는 충분하다
      setCellPx(side > 0 ? side / (size + 1) : 0)
    })
    ro.observe(el)
    return () => ro.disconnect()
  }, [size])

  return { ref, cellPx }
}

/** 설정값 + 실측을 합쳐 좌표를 그릴지 결정 */
export function shouldShowCoords(
  mode: 'auto' | 'on' | 'off',
  cellPx: number,
): boolean {
  if (mode === 'on') return true
  if (mode === 'off') return false
  // 아직 측정 전이면 일단 표시 — 깜빡임보다 낫다
  return cellPx === 0 || cellPx >= MIN_COORD_CELL_PX
}

/**
 * 착수 방식 기본값.
 * 19줄에서 50px 터치 타깃은 폰에서 산술적으로 불가능하므로
 * (50 × 19 = 950px) 큰 판·터치 기기에서는 확정 방식을 기본으로 둔다.
 */
export function defaultPlaceMode(size: BoardSize): 'direct' | 'confirm' {
  const coarse =
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches
  return coarse || size >= 13 ? 'confirm' : 'direct'
}
