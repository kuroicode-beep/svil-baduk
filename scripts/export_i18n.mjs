// scripts/export_i18n.mjs
// src/i18n/dict.ts → app/lib/i18n/strings.g.dart
//
// 155키 × 5언어 = 775 문자열을 손으로 옮기지 않는다.
//
// slang 대신 직접 생성하는 이유: 이 사전은 보간·복수형·중첩이 없는 평평한
// key → {ko,en,ja,zh,vi} 구조라서, 생성된 Dart 상수 접근자만으로 컴파일 타임
// 키 안전성이 확보된다. codegen 패키지와 build_runner 를 붙일 이유가 없고,
// "의존성 최소" 하우스 관례에도 맞는다.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const src = readFileSync(join(root, 'src/i18n/dict.ts'), 'utf8')

const LANGS = ['ko', 'en', 'ja', 'zh', 'vi']

// key: { ko: '...', en: '...', ... }  블록을 잡는다
const entryRe = /^\s{2}([A-Za-z][A-Za-z0-9]*)\s*:\s*\{([^}]*)\}\s*,?\s*$/gm
const valueRe = /(ko|en|ja|zh|vi)\s*:\s*'((?:[^'\\]|\\.)*)'/g

const entries = []
for (const m of src.matchAll(entryRe)) {
  const [, key, body] = m
  const values = {}
  for (const v of body.matchAll(valueRe)) {
    values[v[1]] = v[2].replace(/\\'/g, "'").replace(/\\\\/g, '\\')
  }
  if (Object.keys(values).length === 0) continue
  entries.push({ key, values })
}

if (entries.length === 0) {
  console.error('dict.ts 에서 항목을 찾지 못했습니다 — 형식이 바뀌었는지 확인하세요.')
  process.exit(1)
}

// 중복 키 검사 — TS 객체 리터럴은 뒤에 온 값이 조용히 이깁니다.
// 여기서 안 잡으면 Dart 컴파일 오류로 밀려나고, 원인이 dict.ts 라는 게
// 한눈에 안 보입니다.
const seen = new Map()
const dupes = []
for (const e of entries) {
  if (seen.has(e.key)) dupes.push(`${e.key} (${seen.get(e.key)}번째와 중복)`)
  else seen.set(e.key, entries.indexOf(e) + 1)
}
if (dupes.length > 0) {
  console.error(`중복 키 ${dupes.length}건:\n  ${dupes.join('\n  ')}`)
  process.exit(1)
}

// 누락 언어 검사 — 빌드를 깨뜨려서 조용한 폴백을 막는다
const missing = []
for (const e of entries) {
  for (const l of LANGS) {
    if (typeof e.values[l] !== 'string' || e.values[l].length === 0) {
      missing.push(`${e.key}.${l}`)
    }
  }
}
if (missing.length > 0) {
  console.error(`번역 누락 ${missing.length}건:\n  ${missing.slice(0, 20).join('\n  ')}`)
  process.exit(1)
}

const q = (s) => JSON.stringify(s)
const dartKey = (k) => (k === 'default' || k === 'is' || k === 'in' ? `${k}_` : k)

const out = [
  '// lib/i18n/strings.g.dart — 5개 언어 문자열',
  '//',
  '// 자동 생성 파일. 손으로 고치지 말 것.',
  '// 원본: src/i18n/dict.ts · 생성: npm run i18n:export',
  '',
  'enum Lang {',
  ...LANGS.map((l) => `  ${l}('${l}'),`).map((s, i, a) =>
    i === a.length - 1 ? s.replace(/,$/, ';') : s,
  ),
  '',
  '  const Lang(this.code);',
  '  final String code;',
  '',
  '  static Lang fromCode(String c) =>',
  '      Lang.values.firstWhere((Lang l) => l.code == c, orElse: () => Lang.ko);',
  '}',
  '',
  'const Map<Lang, String> langLabels = <Lang, String>{',
  "  Lang.ko: '한국어',",
  "  Lang.en: 'English',",
  "  Lang.ja: '日本語',",
  "  Lang.zh: '中文',",
  "  Lang.vi: 'Tiếng Việt',",
  '};',
  '',
  '/// 문자열 하나 — 언어별 값을 모두 갖는다',
  'class LocString {',
  '  const LocString(this.ko, this.en, this.ja, this.zh, this.vi);',
  '  final String ko;',
  '  final String en;',
  '  final String ja;',
  '  final String zh;',
  '  final String vi;',
  '',
  '  String call(Lang l) => switch (l) {',
  '        Lang.ko => ko,',
  '        Lang.en => en,',
  '        Lang.ja => ja,',
  '        Lang.zh => zh,',
  '        Lang.vi => vi,',
  '      };',
  '}',
  '',
  '/// 모든 문자열. 오타는 컴파일 오류가 된다.',
  'abstract final class S {',
]

for (const e of entries) {
  const v = e.values
  out.push(
    `  static const LocString ${dartKey(e.key)} = LocString(${q(v.ko)}, ${q(v.en)}, ${q(v.ja)}, ${q(v.zh)}, ${q(v.vi)});`,
  )
}

out.push('}')
out.push('')
out.push('/// 완전성 테스트용 — 생성된 문자열 개수')
out.push(`const int generatedStringCount = ${entries.length};`)
out.push('')
out.push('/// 완전성 테스트용 — 키 이름과 값 목록')
out.push('const Map<String, LocString> allStrings = <String, LocString>{')
for (const e of entries) {
  out.push(`  ${q(e.key)}: S.${dartKey(e.key)},`)
}
out.push('};')

mkdirSync(join(root, 'app/lib/i18n'), { recursive: true })
writeFileSync(join(root, 'app/lib/i18n/strings.g.dart'), out.join('\n') + '\n')
console.log(
  `export_i18n: ${entries.length}키 × ${LANGS.length}언어 = ${entries.length * LANGS.length} 문자열`,
)
