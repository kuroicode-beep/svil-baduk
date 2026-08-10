// scripts/sync-version.mjs
// src/version.ts 의 APP_VERSION 을 단일 진실로 삼아 VERSION · package.json · README 를 맞춘다.
// prebuild 훅에서 자동 실행되며, --check 로 CI 검증만 할 수도 있다.

import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const checkOnly = process.argv.includes('--check')

/** src/version.ts 에서 APP_VERSION 값을 읽는다 */
function readAppVersion() {
  const src = readFileSync(join(root, 'src/version.ts'), 'utf8')
  const m = src.match(/APP_VERSION\s*=\s*['"]([^'"]+)['"]/)
  if (!m) throw new Error('src/version.ts 에서 APP_VERSION 을 찾지 못했습니다')
  if (!/^\d+\.\d+\.\d+$/.test(m[1])) {
    throw new Error(`APP_VERSION 이 SemVer 형식이 아닙니다: ${m[1]}`)
  }
  return m[1]
}

const version = readAppVersion()
const drift = []

/** 파일을 읽어 변환하고, 달라졌으면 쓰거나(기본) 어긋남으로 기록한다(--check) */
function sync(relPath, transform) {
  const path = join(root, relPath)
  const before = readFileSync(path, 'utf8')
  const after = transform(before)
  if (before === after) return
  if (checkOnly) {
    drift.push(relPath)
    return
  }
  writeFileSync(path, after)
  console.log(`  sync-version: ${relPath} → ${version}`)
}

sync('VERSION', () => `${version}\n`)

sync('package.json', (s) => s.replace(/("version"\s*:\s*")[^"]+(")/, `$1${version}$2`))

sync('README.md', (s) =>
  s.replace(/(현재\s*)\d+\.\d+\.\d+/g, `$1${version}`),
)

if (checkOnly && drift.length > 0) {
  console.error(
    `버전 불일치 (src/version.ts = ${version}): ${drift.join(', ')}\n` +
      '  npm run version:sync 로 맞추세요.',
  )
  process.exit(1)
}

if (!checkOnly) console.log(`sync-version: ${version}`)
