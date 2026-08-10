// src/components/AppShell.tsx — 모든 화면을 감싸는 껍데기
//
// 0.8.x 까지는 앱 셸이 없어서 화면마다 제목·뒤로 버튼을 따로 그렸고,
// 버전 배지는 홈에만 있었으며, 화면이 바뀔 때 포커스가 아무 데도 가지 않았다.
// 대국 화면은 전체화면으로 진입하면 홈으로 돌아갈 통로가 사라지기도 했다.

import { useEffect, useRef, type ReactNode } from 'react'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import type { Screen } from '../router/routes'
import { APP_VERSION } from '../version'

interface AppShellProps {
  lang: Lang
  screen: Screen
  /** 대국 화면은 헤더를 낮춰 보드에 자리를 내준다 */
  immersive?: boolean
  onNavigate: (screen: Screen) => void
  children: ReactNode
}

const TITLE_KEY: Record<Screen, 'appTitle' | 'learn' | 'solo' | 'multi' | 'settings' | 'profile'> = {
  home: 'appTitle',
  learn: 'learn',
  solo: 'solo',
  multi: 'multi',
  settings: 'settings',
  profile: 'profile',
}

export function AppShell({ lang, screen, immersive, onNavigate, children }: AppShellProps) {
  const mainRef = useRef<HTMLElement>(null)
  const firstRender = useRef(true)
  const title = t(lang, TITLE_KEY[screen])

  // 화면이 바뀌면 본문으로 포커스를 옮긴다. 첫 렌더에서는 뺏지 않는다.
  useEffect(() => {
    if (firstRender.current) {
      firstRender.current = false
      return
    }
    mainRef.current?.focus()
  }, [screen])

  return (
    <div className={`app-shell${immersive ? ' app-shell--immersive' : ''}`}>
      <a className="skip-link" href="#main">
        {t(lang, 'skipToMain')}
      </a>

      <header className="app-header" role="banner">
        <div className="app-header-left">
          {screen !== 'home' && (
            <button
              type="button"
              className="btn app-header-btn"
              onClick={() => onNavigate('home')}
            >
              {t(lang, 'home')}
            </button>
          )}
          <h1 className="app-header-title">{title}</h1>
        </div>
        <div className="app-header-right">
          <span className="version-badge mono" aria-label={`${t(lang, 'version')} ${APP_VERSION}`}>
            v{APP_VERSION}
          </span>
          {screen !== 'settings' && (
            <button
              type="button"
              className="btn app-header-btn"
              onClick={() => onNavigate('settings')}
            >
              {t(lang, 'settings')}
            </button>
          )}
        </div>
      </header>

      {/* 화면 전환을 스크린리더에 알린다 — 포커스 이동만으로는 맥락이 부족하다 */}
      <p className="sr-only" role="status" aria-live="polite" aria-atomic="true">
        {title}
      </p>

      <main id="main" className="app-main" ref={mainRef} tabIndex={-1}>
        {children}
      </main>
    </div>
  )
}
