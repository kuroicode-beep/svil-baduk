// tools/engine_diff.mjs
// TS 엔진으로 무작위 대국을 두고, 매 수마다 "어떤 착수가 합법이었는지"를 기록한다.
// Dart 쪽이 같은 수순을 재생하며 같은 판정을 내는지 비교한다.
//
// 시드 고정 난수를 쓰므로 양쪽이 정확히 같은 대국을 본다.

import { writeFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { createGame, tryPlay, pass, legalMoves } from '../src/engine/board.ts'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')

/** mulberry32 — 재현 가능한 난수 */
function rng(seed) {
  return function () {
    seed |= 0
    seed = (seed + 0x6d2b79f5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const GAMES = Number(process.env.DIFF_GAMES ?? 500)
const MAX_MOVES = 120
const SIZES = [9, 13, 19]

const cases = []

for (let g = 0; g < GAMES; g++) {
  const rand = rng(1000 + g)
  const size = SIZES[g % SIZES.length]
  let state = createGame(size)
  const moves = []
  const checks = []

  for (let ply = 0; ply < MAX_MOVES && !state.ended; ply++) {
    const legal = legalMoves(state)
    if (legal.length === 0) {
      const r = pass(state)
      if (!r.ok) break
      state = r.state
      moves.push({ pass: true })
      continue
    }

    // 가끔 패스를 섞어 종국·패스 경로도 지나가게 한다
    if (rand() < 0.03) {
      const r = pass(state)
      if (!r.ok) break
      state = r.state
      moves.push({ pass: true })
      continue
    }

    // 이 시점의 합법 지점 집합을 기록 — Dart 가 똑같이 판정해야 한다
    checks.push({
      ply: moves.length,
      legal: legal.map((p) => [p.x, p.y]),
    })

    const pick = legal[Math.floor(rand() * legal.length)]
    const r = tryPlay(state, pick.x, pick.y)
    if (!r.ok) break
    state = r.state
    moves.push({ x: pick.x, y: pick.y })
  }

  cases.push({
    seed: 1000 + g,
    size,
    moves,
    checks,
    final: {
      board: Array.from(state.board),
      toPlay: state.toPlay,
      blackCaptures: state.captures[1],
      whiteCaptures: state.captures[2],
      ended: state.ended,
      consecutivePasses: state.consecutivePasses,
    },
  })
}

mkdirSync(join(root, 'app/test/fixtures'), { recursive: true })
writeFileSync(
  join(root, 'app/test/fixtures/engine_diff.json'),
  JSON.stringify({ generatedBy: 'tools/engine_diff.mjs', games: cases }),
)

const totalChecks = cases.reduce((n, c) => n + c.checks.length, 0)
const totalMoves = cases.reduce((n, c) => n + c.moves.length, 0)
console.log(
  `engine_diff: ${cases.length}판, ${totalMoves}수, 합법성 검증지점 ${totalChecks}곳`,
)
