export interface HistoryEntry {
  version: string
  date: string
  lines: string[]
}

export const CHANGELOG: HistoryEntry[] = [
  {
    version: '0.1.0',
    date: '2026-07-23',
    lines: [
      '고대비 바둑 MVP 골격 (React + Vite)',
      '단계별 배우기 / 혼자서 두기(급·단) / P2P 멀티',
      '착수점 깜빡임·키보드 착수·KataGo GTP 스텁',
    ],
  },
]
