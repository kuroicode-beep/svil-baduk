// scripts/sync-version.mjs
// src/version.ts 의 APP_VERSION 을 단일 진실로 삼아 VERSION · package.json · README 를 맞춘다.
// prebuild 훅에서 자동 실행되며, --check 로 CI 검증만 할 수도 있다.

import { existsSync, readFileSync, writeFileSync } from 'node:fs'
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

/** 아직 없을 수 있는 파일 (Flutter 앱은 단계적으로 들어온다) */
function syncOptional(relPath, transform) {
  if (!existsSync(join(root, relPath))) return
  sync(relPath, transform)
}

sync('VERSION', () => `${version}\n`)

sync('package.json', (s) => s.replace(/("version"\s*:\s*")[^"]+(")/, `$1${version}$2`))

sync('README.md', (s) =>
  s.replace(/(현재\s*)\d+\.\d+\.\d+/g, `$1${version}`),
)

/* Flutter 앱 — pubspec 의 빌드 번호(+N)는 보존한다 */
syncOptional('app/pubspec.yaml', (s) =>
  s.replace(/^(version:\s*)\d+\.\d+\.\d+(\+\d+)?/m, (_m, head, build) =>
    `${head}${version}${build ?? ''}`,
  ),
)

syncOptional('app/lib/version.dart', (s) =>
  s.replace(/(appVersion\s*=\s*')[^']+(')/, `$1${version}$2`),
)

/* Tauri 셸 — 여기가 빠져 있어서 0.9.x 와 0.8.0 이 갈라져 있었다.
   설치본이 조용히 옛 버전으로 찍히던 버그의 원인. */
syncOptional('src-tauri/tauri.conf.json', (s) =>
  s.replace(/("version"\s*:\s*")[^"]+(")/, `$1${version}$2`),
)

syncOptional('src-tauri/Cargo.toml', (s) =>
  s.replace(/^(version\s*=\s*")[^"]+(")/m, `$1${version}$2`),
)

if (checkOnly && drift.length > 0) {
  console.error(
    `버전 불일치 (src/version.ts = ${version}): ${drift.join(', ')}\n` +
      '  npm run version:sync 로 맞추세요.',
  )
  process.exit(1)
}

if (!checkOnly) console.log(`sync-version: ${version}`)
