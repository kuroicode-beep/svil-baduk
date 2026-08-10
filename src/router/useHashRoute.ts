// src/router/useHashRoute.ts — location.hash 를 화면 상태로 쓰는 최소 라우터
import { useCallback, useEffect, useState } from 'react'
import { hashForScreen, screenFromHash, type Screen } from './routes'

export interface HashRoute {
  screen: Screen
  navigate: (screen: Screen, opts?: { replace?: boolean }) => void
}

export function useHashRoute(): HashRoute {
  const [screen, setScreen] = useState<Screen>(() =>
    screenFromHash(typeof window === 'undefined' ? '' : window.location.hash),
  )

  useEffect(() => {
    const onHashChange = () => setScreen(screenFromHash(window.location.hash))
    window.addEventListener('hashchange', onHashChange)
    // 초기 해시가 비정상이면(예: #/없는화면) 상태와 맞춰준다
    onHashChange()
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  const navigate = useCallback((next: Screen, opts?: { replace?: boolean }) => {
    const hash = hashForScreen(next)
    if (window.location.hash === hash) {
      setScreen(next)
      return
    }
    if (opts?.replace) {
      // 히스토리를 남기지 않는다 (스냅샷 자동 복원 등)
      const url = `${window.location.pathname}${window.location.search}${hash}`
      window.history.replaceState(null, '', url)
      setScreen(next)
    } else {
      window.location.hash = hash
    }
  }, [])

  return { screen, navigate }
}
