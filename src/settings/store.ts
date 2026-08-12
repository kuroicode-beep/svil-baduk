import type { Lang } from '../i18n/dict'
import type { GoRules } from '../engine/scoring'
import type { BlackStoneId, WhiteStoneId } from './stoneColors'

export type FontId =
  | 'kyobo'
  | 'gothic'
  | 'nanum'
  | 'lineseed'
  | 'gowun'
  | 'cafe24'
  | 'tmoney'
  | 'reco'

export type FontSizeId = 'small' | 'medium' | 'large'
export type BoardScaleId = 'small' | 'medium' | 'large'
export type LineWeightId = 'thin' | 'normal' | 'thick'

/** 'system' 은 OS 설정을 그때그때 따른다 (한 번만 시딩하면 나중에 켠 사용자에게 반영되지 않는다) */
export type ReduceMotionSetting = boolean | 'system'

export interface Settings {
  lang: Lang
  font: FontId
  fontSize: FontSizeId
  blinkIntersections: boolean
  maxContrastBoard: boolean
  /** 버튼 글자·테두리 대비를 WCAG 이상으로 강제 */
  strongButtonContrast: boolean
  reduceMotion: ReduceMotionSetting
  moveSound: boolean
  boardScale: BoardScaleId
  lineWeight: LineWeightId
  goRules: GoRules
  /** 좌표 눈금 — 'auto' 는 칸이 너무 작아지면 자동으로 숨긴다 */
  boardCoords: 'auto' | 'on' | 'off'
  /** 착수 방식 — 좁은 화면·큰 판에서는 확정 방식이 기본 */
  placeMode: 'direct' | 'confirm'
  blackStone: BlackStoneId
  whiteStone: WhiteStoneId
  katagoBridgeUrl: string
  katagoExe: string
  katagoModel: string
  katagoConfig: string
  katagoAutoConnect: boolean
}

const KEY = 'svil-baduk-settings'

export const FONT_OPTIONS: { id: FontId; label: string; css: string }[] = [
  { id: 'kyobo', label: '교보손글씨2019', css: '"KyoboHandwriting2019", "Segoe UI", sans-serif' },
  { id: 'gothic', label: '고딕', css: '"Malgun Gothic", "Segoe UI", sans-serif' },
  { id: 'nanum', label: '나눔고딕', css: '"NanumGothic", "Malgun Gothic", sans-serif' },
  { id: 'lineseed', label: '라인시드', css: '"LINESeedKR", "Malgun Gothic", sans-serif' },
  { id: 'gowun', label: '고운돋움', css: '"GowunDodum", "Malgun Gothic", sans-serif' },
  { id: 'cafe24', label: '카페24동동', css: '"Cafe24Dongdong", "Malgun Gothic", sans-serif' },
  { id: 'tmoney', label: '티머니둥근바람', css: '"TmoneyRoundWind", "Malgun Gothic", sans-serif' },
  { id: 'reco', label: '레코', css: '"Reco", "Malgun Gothic", sans-serif' },
]

export const FONT_SIZE_PX: Record<FontSizeId, number> = {
  small: 16,
  medium: 18,
  large: 20,
}

/**
 * 판이 차지하는 최대 폭. 예전의 BOARD_CELL_PX 는 viewBox 셀 크기만 바꿔서
 * 화면상 판 크기가 전혀 달라지지 않았고, 오히려 고정 크기 마커가 상대적으로
 * 작아지는 역효과가 났다. 이제는 패널 폭을 내주고 판이 실제로 커진다.
 */
export const BOARD_MAX_VMIN: Record<BoardScaleId, number> = {
  small: 68,
  medium: 78,
  large: 90,
}

/** 판이 커지는 만큼 우측 패널이 좁아진다 */
export const PANEL_WIDTH_PX: Record<BoardScaleId, number> = {
  small: 340,
  medium: 300,
  large: 260,
}

export const LINE_STROKE: Record<LineWeightId, number> = {
  thin: 1.5,
  normal: 2.5,
  thick: 4,
}

/** 저장 스키마 버전 — 구조가 바뀌면 올리고 migrateSettings 에 분기를 추가한다 */
export const SETTINGS_VERSION = 1

function media(query: string): boolean {
  if (typeof window === 'undefined' || !window.matchMedia) return false
  return window.matchMedia(query).matches
}

export function prefersReducedMotion(): boolean {
  return media('(prefers-reduced-motion: reduce)')
}

export function prefersMoreContrast(): boolean {
  return media('(prefers-contrast: more)')
}

/** 'system' 을 지금 시점의 OS 설정으로 해석 */
export function resolveReduceMotion(v: ReduceMotionSetting): boolean {
  return v === 'system' ? prefersReducedMotion() : v
}

export const defaultSettings = (): Settings => ({
  lang: 'ko',
  font: 'kyobo',
  fontSize: 'medium',
  blinkIntersections: true,
  maxContrastBoard: true,
  strongButtonContrast: true,
  reduceMotion: 'system',
  moveSound: true,
  boardScale: 'medium',
  lineWeight: 'normal',
  goRules: 'japanese',
  boardCoords: 'auto',
  placeMode: 'direct',
  blackStone: 'black',
  whiteStone: 'white',
  katagoBridgeUrl: 'http://127.0.0.1:17419',
  katagoExe: '',
  katagoModel: '',
  katagoConfig: '',
  katagoAutoConnect: true,
})

type StoredSettings = Settings & { v?: number }

/**
 * 저장값을 현재 스키마로 올린다.
 * v 가 없으면 0.8.x 이하(버전 필드 없음)로 보고 v1 로 승격한다.
 */
export function migrateSettings(raw: unknown): Settings {
  const base = defaultSettings()
  if (!raw || typeof raw !== 'object') return base
  const stored = raw as StoredSettings
  const merged: Settings = { ...base, ...stored }

  if (stored.v === undefined) {
    // v0: reduceMotion 이 boolean 뿐이었다. 명시적으로 켠 값만 유지하고
    // 꺼둔(=기본값) 사용자는 OS 설정을 따르도록 'system' 으로 올린다.
    merged.reduceMotion = stored.reduceMotion === true ? true : 'system'
  }

  // 값 검증 — 손상된 저장값이 앱을 깨뜨리지 않게
  if (!['small', 'medium', 'large'].includes(merged.fontSize)) merged.fontSize = base.fontSize
  if (!FONT_OPTIONS.some((f) => f.id === merged.font)) merged.font = base.font
  if (!['small', 'medium', 'large'].includes(merged.boardScale)) merged.boardScale = base.boardScale
  if (!['thin', 'normal', 'thick'].includes(merged.lineWeight)) merged.lineWeight = base.lineWeight
  if (!['auto', 'on', 'off'].includes(merged.boardCoords)) merged.boardCoords = base.boardCoords
  if (!['direct', 'confirm'].includes(merged.placeMode)) merged.placeMode = base.placeMode
  if (merged.reduceMotion !== 'system' && typeof merged.reduceMotion !== 'boolean') {
    merged.reduceMotion = base.reduceMotion
  }
  return merged
}

export function loadSettings(): Settings {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) {
      // 첫 실행: OS 고대비 선호를 반영
      const s = defaultSettings()
      if (prefersMoreContrast()) s.maxContrastBoard = true
      return s
    }
    return migrateSettings(JSON.parse(raw))
  } catch {
    return defaultSettings()
  }
}

export function saveSettings(s: Settings) {
  localStorage.setItem(KEY, JSON.stringify({ v: SETTINGS_VERSION, ...s }))
}

/** 설정 전체 초기화 */
export function resetSettings(): Settings {
  const s = defaultSettings()
  saveSettings(s)
  return s
}
