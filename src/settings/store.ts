import type { Lang } from '../i18n/dict'

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

export interface Settings {
  lang: Lang
  font: FontId
  fontSize: FontSizeId
  blinkIntersections: boolean
  maxContrastBoard: boolean
  reduceMotion: boolean
  moveSound: boolean
  boardScale: BoardScaleId
  lineWeight: LineWeightId
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

export const BOARD_CELL_PX: Record<BoardScaleId, number> = {
  small: 40,
  medium: 48,
  large: 60,
}

export const LINE_STROKE: Record<LineWeightId, number> = {
  thin: 1.5,
  normal: 2.5,
  thick: 4,
}

export const defaultSettings = (): Settings => ({
  lang: 'ko',
  font: 'kyobo',
  fontSize: 'medium',
  blinkIntersections: true,
  maxContrastBoard: true,
  reduceMotion: false,
  moveSound: true,
  boardScale: 'medium',
  lineWeight: 'normal',
  katagoBridgeUrl: 'http://127.0.0.1:17419',
  katagoExe: '',
  katagoModel: '',
  katagoConfig: '',
  katagoAutoConnect: true,
})

export function loadSettings(): Settings {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return defaultSettings()
    return { ...defaultSettings(), ...JSON.parse(raw) }
  } catch {
    return defaultSettings()
  }
}

export function saveSettings(s: Settings) {
  localStorage.setItem(KEY, JSON.stringify(s))
}
