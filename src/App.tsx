import { useEffect, useRef, useState } from 'react'
import { connectBridge } from './ai/bridgeTransport'
import { AppShell } from './components/AppShell'
import { isEmptyHash } from './router/routes'
import { useHashRoute } from './router/useHashRoute'
import { Home } from './screens/Home'
import { Learn } from './screens/Learn'
import { Multi } from './screens/Multi'
import { ProfileScreen } from './screens/Profile'
import { SettingsScreen } from './screens/Settings'
import { Solo } from './screens/Solo'
import {
  BOARD_MAX_VMIN,
  FONT_OPTIONS,
  FONT_SIZE_PX,
  PANEL_WIDTH_PX,
  loadSettings,
  resolveReduceMotion,
  saveSettings,
  type Settings,
} from './settings/store'
import { loadSoloSnapshot } from './solo/snapshot'
import './App.css'

export default function App() {
  const { screen, navigate } = useHashRoute()
  const [settings, setSettings] = useState<Settings>(() => loadSettings())
  const restored = useRef(false)

  /* 미종료 스냅샷이 있으면 대국 화면으로 복원한다.
     단 해시가 비어 있을 때만 — 딥링크(#/settings 등)를 가로채면 안 된다. */
  useEffect(() => {
    if (restored.current) return
    restored.current = true
    if (!isEmptyHash(window.location.hash)) return
    const snap = loadSoloSnapshot()
    if (snap && !snap.state.ended) navigate('solo', { replace: true })
  }, [navigate])

  /* reduceMotion:'system' 을 해석한 값. OS 설정이 바뀌면 즉시 따라간다 —
     한 번만 시딩하면 나중에 켠 사용자에게 영영 반영되지 않는다. */
  const [systemMotionTick, setSystemMotionTick] = useState(0)
  useEffect(() => {
    if (!window.matchMedia) return
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    const onChange = () => setSystemMotionTick((n) => n + 1)
    mq.addEventListener?.('change', onChange)
    return () => mq.removeEventListener?.('change', onChange)
  }, [])
  void systemMotionTick // OS 변경 시 재계산 트리거
  const reduceMotion = resolveReduceMotion(settings.reduceMotion)

  useEffect(() => {
    saveSettings(settings)
    const root = document.documentElement
    root.lang = settings.lang
    root.style.setProperty('--font-base', `${FONT_SIZE_PX[settings.fontSize]}px`)
    const font = FONT_OPTIONS.find((f) => f.id === settings.font)?.css
    if (font) root.style.setProperty('--font-ui', font)
    root.dataset.reduceMotion = reduceMotion ? '1' : '0'
    root.dataset.buttonContrast = settings.strongButtonContrast ? 'strong' : 'normal'
    // 바둑판 고대비 — Board.tsx 의 색 분기를 대신한다
    root.dataset.boardContrast = settings.maxContrastBoard ? 'max' : 'normal'
    // 판 크기 설정이 실제로 판을 키운다 (패널 폭을 내주는 방식)
    root.style.setProperty('--board-max', `${BOARD_MAX_VMIN[settings.boardScale]}vmin`)
    root.style.setProperty('--panel-w', `${PANEL_WIDTH_PX[settings.boardScale]}px`)
  }, [settings, reduceMotion])

  useEffect(() => {
    if (!settings.katagoAutoConnect) return
    let cancelled = false
    let attempt = 0
    const paths = {
      exe: settings.katagoExe || undefined,
      model: settings.katagoModel || undefined,
      config: settings.katagoConfig || undefined,
    }
    const tryConnect = async () => {
      while (!cancelled && attempt < 12) {
        attempt += 1
        const r = await connectBridge(settings.katagoBridgeUrl, paths)
        if (r.ok || cancelled) return
        // 브리지 기동·OpenCL 튜닝 대기 (최대 ~2분)
        await new Promise((res) => setTimeout(res, attempt < 3 ? 2000 : 10000))
      }
    }
    void tryConnect()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [settings.katagoAutoConnect, settings.katagoBridgeUrl])

  const immersive = screen === 'solo' || screen === 'multi'

  return (
    <div className="app">
      <AppShell lang={settings.lang} screen={screen} immersive={immersive} onNavigate={navigate}>
        {screen === 'home' && <Home lang={settings.lang} onNavigate={navigate} />}
        {screen === 'learn' && (
          <Learn lang={settings.lang} settings={settings} />
        )}
        {screen === 'solo' && (
          <Solo lang={settings.lang} settings={settings} />
        )}
        {screen === 'multi' && (
          <Multi lang={settings.lang} settings={settings} />
        )}
        {screen === 'settings' && (
          <SettingsScreen
            lang={settings.lang}
            settings={settings}
            onChange={setSettings}
          />
        )}
        {screen === 'profile' && <ProfileScreen lang={settings.lang} />}
      </AppShell>
    </div>
  )
}
