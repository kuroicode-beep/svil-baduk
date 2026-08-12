// scripts/export_curriculum.mjs
// src/learn/curriculum.ts → app/assets/learn/curriculum.json
//
// 693줄 중 약 693줄이 순수 데이터다. 손으로 옮기지 않는다.
// TS 를 직접 import 해서 런타임 값을 그대로 직렬화하므로, 형식이 바뀌어도
// 파서를 고칠 필요가 없다.

import { writeFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { STAGES } from '../src/learn/curriculum.ts'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')

const LANGS = ['ko', 'en', 'ja', 'zh', 'vi']

/** LocString 을 그대로 옮기되 ko 가 없으면 실패시킨다 */
function loc(value, where) {
  if (!value || typeof value !== 'object' || typeof value.ko !== 'string') {
    throw new Error(`${where}: ko 번역이 없습니다`)
  }
  const out = {}
  for (const l of LANGS) {
    if (typeof value[l] === 'string' && value[l].length > 0) out[l] = value[l]
  }
  return out
}

/** ASCII 배치를 흑·백 좌표 목록으로 — Dart 쪽 모델이 단순해진다 */
function stonesFromSetup(rows, size, where) {
  if (rows.length !== size) {
    throw new Error(`${where}: 행 수 ${rows.length} != 판 크기 ${size}`)
  }
  const black = []
  const white = []
  rows.forEach((row, y) => {
    if (row.length !== size) {
      throw new Error(`${where}: ${y}행 길이 ${row.length} != ${size}`)
    }
    for (let x = 0; x < size; x++) {
      const ch = row[x]
      if (ch === 'B' || ch === 'X') black.push([x, y])
      else if (ch === 'W' || ch === 'O') white.push([x, y])
      else if (ch !== '.') throw new Error(`${where}: 알 수 없는 문자 '${ch}'`)
    }
  })
  return { black, white }
}

const seenIds = new Set()
const stages = STAGES.map((stage) => {
  const problems = stage.problems.map((p) => {
    const where = `${stage.id}/${p.id}`
    if (seenIds.has(p.id)) throw new Error(`${where}: 중복 id`)
    seenIds.add(p.id)

    const { black, white } = stonesFromSetup(p.setup, p.size, where)
    for (const s of p.solutions) {
      if (s.x < 0 || s.y < 0 || s.x >= p.size || s.y >= p.size) {
        throw new Error(`${where}: 정답 좌표가 판 밖 (${s.x},${s.y})`)
      }
    }
    if (p.solutions.length === 0) throw new Error(`${where}: 정답이 없습니다`)

    return {
      id: p.id,
      title: loc(p.title, `${where}.title`),
      goalLabel: loc(p.goalLabel, `${where}.goalLabel`),
      goal: p.goal,
      size: p.size,
      toPlay: p.toPlay,
      black,
      white,
      solutions: p.solutions.map((s) => [s.x, s.y]),
      hint: loc(p.hint, `${where}.hint`),
      ...(p.note ? { note: loc(p.note, `${where}.note`) } : {}),
    }
  })

  return {
    id: stage.id,
    track: stage.track,
    order: stage.order,
    title: loc(stage.title, `${stage.id}.title`),
    blurb: loc(stage.blurb, `${stage.id}.blurb`),
    refs: loc(stage.refs, `${stage.id}.refs`),
    problems,
  }
})

const out = { schema: 1, stages }

mkdirSync(join(root, 'app/assets/learn'), { recursive: true })
writeFileSync(
  join(root, 'app/assets/learn/curriculum.json'),
  JSON.stringify(out, null, 1),
)

const problemCount = stages.reduce((n, s) => n + s.problems.length, 0)
console.log(
  `export_curriculum: ${stages.length}스테이지 ${problemCount}문제 ` +
    `(트랙 ${[...new Set(stages.map((s) => s.track))].join(', ')})`,
)
