// src/styles/tokens.test.ts — 디자인 토큰이 실제로 쓰이는지 강제하는 가드레일
//
// 0.8.0 까지는 :root 에 토큰이 선언만 되어 있고 App.css 1299줄은 px 리터럴이었다.
// (--gap 은 사용처가 0곳이었다) 이 테스트가 없으면 같은 일이 반복된다.

import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const SRC = join(process.cwd(), 'src')
const STYLES = join(SRC, 'styles')

/**
 * src 전체를 재귀로 훑는다.
 * 예전엔 src/components 한 겹만 읽어서 src/components/board/*.tsx 의
 * var(--board-*) 사용이 통째로 안 보였고, 살아 있는 토큰이 미사용으로 잡혔다.
 */
function walkSource(dir: string, out: string[] = []): string[] {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name)
    if (entry.isDirectory()) walkSource(full, out)
    else if (/\.(tsx?|css)$/.test(entry.name)) out.push(full)
  }
  return out
}

const allSourceFiles = walkSource(SRC)

function cssFiles(): { name: string; text: string }[] {
  const out = readdirSync(STYLES)
    .filter((f) => f.endsWith('.css'))
    .map((f) => ({ name: `styles/${f}`, text: readFileSync(join(STYLES, f), 'utf8') }))
  for (const f of ['index.css', 'App.css']) {
    out.push({ name: f, text: readFileSync(join(SRC, f), 'utf8') })
  }
  return out
}

/** 주석을 제거해 설명문 속 예시가 검사에 걸리지 않게 한다 */
function stripComments(css: string): string {
  return css.replace(/\/\*[\s\S]*?\*\//g, '')
}

const files = cssFiles()
const tokensCss = readFileSync(join(STYLES, 'tokens.css'), 'utf8')
const declared = new Set(
  [...tokensCss.matchAll(/^\s*(--[a-z0-9-]+)\s*:/gim)].map((m) => m[1]),
)

describe('디자인 토큰', () => {
  it('토큰이 tokens.css 한 곳에만 선언된다', () => {
    for (const f of files) {
      if (f.name === 'styles/tokens.css') continue
      const decls = [...stripComments(f.text).matchAll(/^\s*(--[a-z0-9-]+)\s*:/gim)]
      expect(decls.map((d) => d[1]), `${f.name} 에서 토큰을 선언하고 있습니다`).toEqual([])
    }
  })

  it('참조된 var(--x) 가 전부 선언되어 있다', () => {
    const missing: string[] = []
    for (const f of files) {
      for (const m of stripComments(f.text).matchAll(/var\(\s*(--[a-z0-9-]+)/gi)) {
        if (!declared.has(m[1])) missing.push(`${f.name}: ${m[1]}`)
      }
    }
    expect(missing).toEqual([])
  })

  it('선언된 토큰에 미사용이 없다', () => {
    // CSS 든 TSX 든, src 아래 어디서 쓰이면 사용으로 친다
    const usedSomewhere = new Set<string>()
    for (const path of allSourceFiles) {
      const text = readFileSync(path, 'utf8')
      const scanned = path.endsWith('.css') ? stripComments(text) : text
      for (const m of scanned.matchAll(/var\(\s*(--[a-z0-9-]+)/gi)) usedSomewhere.add(m[1])
    }
    const unused = [...declared].filter((d) => !usedSomewhere.has(d))
    expect(unused, '선언만 하고 안 쓰는 토큰 (0.8.0 의 --gap 같은 경우)').toEqual([])
  })

  it('토큰 사용처 스캔이 하위 디렉터리까지 본다', () => {
    // 회귀 방지: 예전 스캔은 src/components 한 겹만 읽어 board/ 를 놓쳤다
    expect(allSourceFiles.some((p) => p.includes('board'))).toBe(true)
    const boardSvg = allSourceFiles.find((p) => p.endsWith('BoardSvg.tsx'))
    expect(boardSvg, 'BoardSvg.tsx 를 스캔 대상에서 찾지 못했습니다').toBeDefined()
  })

  it('간격·모서리에 맨 px 값이 없다', () => {
    const PROPS = /(?:^|;|\{)\s*(gap|row-gap|column-gap|padding|margin|border-radius)\s*:\s*([^;}]+)/gi
    const offenders: string[] = []
    for (const f of files) {
      for (const m of stripComments(f.text).matchAll(PROPS)) {
        const [, prop, value] = m
        // 0, auto, %, dvh/vmin 등 상대 단위, calc/clamp/min/max 는 허용
        const bare = value.match(/(?<![\w-])\d*\.?\d+px/g)
        if (!bare) continue
        if (/\b(calc|clamp|min|max)\s*\(/.test(value)) continue
        offenders.push(`${f.name}: ${prop}: ${value.trim()}`)
      }
    }
    expect(offenders, '토큰(--space-*, --radius*) 을 쓰세요').toEqual([])
  })

  it('글자 크기에 맨 px·rem 리터럴이 없다', () => {
    const offenders: string[] = []
    for (const f of files) {
      for (const m of stripComments(f.text).matchAll(/font-size\s*:\s*([^;}]+)/gi)) {
        const value = m[1].trim()
        if (value.includes('var(--')) continue
        if (/^\d*\.?\d+em$/.test(value)) continue // 부모 상대 배율은 허용
        offenders.push(`${f.name}: font-size: ${value}`)
      }
    }
    expect(offenders, '--text-* 토큰을 쓰세요').toEqual([])
  })

  it('글자 크기 설정이 rem 전체에 반영되도록 루트 font-size 가 걸려 있다', () => {
    // 이게 없으면 rem 이 브라우저 기본 16px 에 묶여 설정이 대부분 안 먹는다
    const index = readFileSync(join(SRC, 'index.css'), 'utf8')
    expect(index).toMatch(/html\s*\{[^}]*font-size:\s*var\(--font-base\)/)
  })

  it('hover 규칙이 (hover: hover) 로 감싸져 있다 — 터치에서 들러붙지 않게', () => {
    const offenders: string[] = []
    for (const f of files) {
      const text = stripComments(f.text)
      // @media (hover: hover) 블록 밖의 :hover 를 찾는다
      const guarded = [...text.matchAll(/@media[^{]*hover:\s*hover[^{]*\{/gi)].map((m) => {
        const start = m.index ?? 0
        let depth = 0
        let i = text.indexOf('{', start)
        for (; i < text.length; i++) {
          if (text[i] === '{') depth++
          else if (text[i] === '}') {
            depth--
            if (depth === 0) break
          }
        }
        return [start, i] as const
      })
      for (const m of text.matchAll(/:hover/g)) {
        const at = m.index ?? 0
        if (!guarded.some(([s, e]) => at > s && at < e)) {
          offenders.push(`${f.name}: ${text.slice(Math.max(0, at - 40), at + 8).trim()}`)
        }
      }
    }
    expect(offenders).toEqual([])
  })
})
