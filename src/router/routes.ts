// src/router/routes.ts — 화면 목록과 해시 문자열 변환
//
// 해시 라우팅을 쓰는 이유: GitHub Pages 는 SPA rewrite 가 없어 pushState 경로가
// 새로고침·딥링크에서 404 가 된다. 해시는 Pages · file:// 에서 설정 없이
// 똑같이 동작하고 뒤로가기도 공짜다.

export const SCREENS = ['home', 'learn', 'solo', 'multi', 'settings', 'profile'] as const

export type Screen = (typeof SCREENS)[number]

export const DEFAULT_SCREEN: Screen = 'home'

export function isScreen(v: unknown): v is Screen {
  return typeof v === 'string' && (SCREENS as readonly string[]).includes(v)
}

/** '#/solo' → 'solo'. 모르는 값이면 홈 */
export function screenFromHash(hash: string): Screen {
  const raw = hash.replace(/^#\/?/, '').split(/[?/]/)[0].trim().toLowerCase()
  return isScreen(raw) ? raw : DEFAULT_SCREEN
}

export function hashForScreen(screen: Screen): string {
  return `#/${screen}`
}

/** 해시가 비어 있는가 — 스냅샷 자동 복원이 딥링크를 가로채지 않게 하는 판단 기준 */
export function isEmptyHash(hash: string): boolean {
  const raw = hash.replace(/^#\/?/, '').trim()
  return raw === ''
}
