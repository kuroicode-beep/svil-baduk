import { useEffect, useState } from 'react'
import { connectBridge } from './ai/bridgeTransport'
import { Home } from './screens/Home'
import { Learn } from './screens/Learn'
import { Multi } from './screens/Multi'
import { SettingsScreen } from './screens/Settings'
import { Solo } from './screens/Solo'
import {
  FONT_OPTIONS,
  FONT_SIZE_PX,
  loadSettings,
  saveSettings,
  type Settings,
} from './settings/store'
import './App.css'

type Screen = 'home' | 'learn' | 'solo' | 'multi' | 'settings'

export default function App() {
  const [screen, setScreen] = useState<Screen>('home')
  const [settings, setSettings] = useState<Settings>(() => loadSettings())

  useEffect(() => {
    saveSettings(settings)
    document.documentElement.lang = settings.lang
    document.documentElement.style.setProperty('--font-base', `${FONT_SIZE_PX[settings.fontSize]}px`)
    const font = FONT_OPTIONS.find((f) => f.id === settings.font)?.css
    if (font) document.documentElement.style.setProperty('--font-ui', font)
    document.documentElement.dataset.reduceMotion = settings.reduceMotion ? '1' : '0'
  }, [settings])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.altKey && e.key === 'ArrowLeft') {
        e.preventDefault()
        setScreen('home')
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

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

  return (
    <div className="app">
      {screen === 'home' && (
        <Home lang={settings.lang} onNavigate={(s) => setScreen(s)} />
      )}
      {screen === 'learn' && (
        <Learn lang={settings.lang} settings={settings} onBack={() => setScreen('home')} />
      )}
      {screen === 'solo' && (
        <Solo lang={settings.lang} settings={settings} onBack={() => setScreen('home')} />
      )}
      {screen === 'multi' && (
        <Multi lang={settings.lang} settings={settings} onBack={() => setScreen('home')} />
      )}
      {screen === 'settings' && (
        <SettingsScreen
          lang={settings.lang}
          settings={settings}
          onChange={setSettings}
          onBack={() => setScreen('home')}
        />
      )}
    </div>
  )
}
