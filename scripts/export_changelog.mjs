// scripts/export_changelog.mjs
// src/history/changelog.ts → app/lib/domain/changelog.dart
//
// 인앱 히스토리가 Flutter 전환 전후로 끊기지 않게, React 판의 항목을
// 손으로 옮기지 않고 기계로 변환한다. 버전을 올릴 때마다 다시 돌린다.

import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const src = readFileSync(join(root, 'src/history/changelog.ts'), 'utf8')

const entryRe = /\{\s*version:\s*'([^']+)',\s*date:\s*'([^']+)',\s*lines:\s*\[([\s\S]*?)\],\s*\}/g
const lineRe = /'((?:[^'\\]|\\.)*)'/g

const entries = []
for (const m of src.matchAll(entryRe)) {
  const [, version, date, body] = m
  const lines = [...body.matchAll(lineRe)].map((l) => l[1].replace(/\\'/g, "'"))
  entries.push({ version, date, lines })
}

if (entries.length === 0) {
  console.error('changelog.ts 에서 항목을 찾지 못했습니다 — 형식이 바뀌었는지 확인하세요.')
  process.exit(1)
}

const q = (s) => JSON.stringify(s)

const out = [
  '// lib/domain/changelog.dart — 인앱 히스토리 (설정 → 히스토리)',
  '//',
  '// 자동 생성 파일. 손으로 고치지 말 것.',
  '// 원본: src/history/changelog.ts · 생성: npm run changelog:export',
  '',
  'class HistoryEntry {',
  '  const HistoryEntry({required this.version, required this.date, required this.lines});',
  '  final String version;',
  '  final String date;',
  '  final List<String> lines;',
  '}',
  '',
  'const List<HistoryEntry> changelog = <HistoryEntry>[',
]

for (const e of entries) {
  out.push('  HistoryEntry(')
  out.push(`    version: ${q(e.version)},`)
  out.push(`    date: ${q(e.date)},`)
  out.push('    lines: <String>[')
  for (const line of e.lines) out.push(`      ${q(line)},`)
  out.push('    ],')
  out.push('  ),')
}
out.push('];')

writeFileSync(join(root, 'app/lib/domain/changelog.dart'), out.join('\n') + '\n')
console.log(
  `export_changelog: ${entries.length}개 버전 이식 (${entries[0].version} … ${entries[entries.length - 1].version})`,
)
