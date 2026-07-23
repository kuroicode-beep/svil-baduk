/** 흑/백 돌 시각 팔레트 — 색만으로 구분하지 않고 보드에 「흑」「백」 라벨 유지 */

export type BlackStoneId = 'black' | 'gray' | 'red' | 'darkOrange'
export type WhiteStoneId = 'white' | 'yellow' | 'sky'

export type StoneStyle = {
  fill: string
  stroke: string
  label: string
}

export const BLACK_STONE_OPTIONS: { id: BlackStoneId; labelKo: string; labelEn: string; style: StoneStyle }[] = [
  { id: 'black', labelKo: '검정', labelEn: 'Black', style: { fill: '#121212', stroke: '#f5f5f7', label: '#f5f5f7' } },
  { id: 'gray', labelKo: '회색', labelEn: 'Gray', style: { fill: '#6b6b82', stroke: '#f5f5f7', label: '#f5f5f7' } },
  { id: 'red', labelKo: '빨강', labelEn: 'Red', style: { fill: '#b71c1c', stroke: '#ffdad6', label: '#ffffff' } },
  {
    id: 'darkOrange',
    labelKo: '짙은 주황',
    labelEn: 'Dark orange',
    style: { fill: '#e65100', stroke: '#ffe0b2', label: '#ffffff' },
  },
]

export const WHITE_STONE_OPTIONS: { id: WhiteStoneId; labelKo: string; labelEn: string; style: StoneStyle }[] = [
  { id: 'white', labelKo: '흰색', labelEn: 'White', style: { fill: '#f5f5f7', stroke: '#000000', label: '#000000' } },
  { id: 'yellow', labelKo: '노랑', labelEn: 'Yellow', style: { fill: '#ffd479', stroke: '#000000', label: '#000000' } },
  { id: 'sky', labelKo: '하늘색', labelEn: 'Sky', style: { fill: '#7ec8ff', stroke: '#00344f', label: '#00344f' } },
]

export function blackStoneStyle(id: BlackStoneId): StoneStyle {
  return BLACK_STONE_OPTIONS.find((o) => o.id === id)?.style ?? BLACK_STONE_OPTIONS[0].style
}

export function whiteStoneStyle(id: WhiteStoneId): StoneStyle {
  return WHITE_STONE_OPTIONS.find((o) => o.id === id)?.style ?? WHITE_STONE_OPTIONS[0].style
}
