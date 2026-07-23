import { useEffect, useState } from 'react'
import {
  connectBridge,
  disconnectBridge,
  probeBridge,
  type BridgeHealth,
} from '../ai/bridgeTransport'
import { detectComputeHint, type ComputeHint } from '../ai/detectCompute'
import { isKataGoAvailable, KATAGO_SETUP_HINT } from '../ai/katago'
import { playMoveSound } from '../audio/moveSound'
import { CHANGELOG } from '../history/changelog'
import { LANG_LABELS, type Lang, t } from '../i18n/dict'
import {
  FONT_OPTIONS,
  type BoardScaleId,
  type FontId,
  type FontSizeId,
  type LineWeightId,
  type Settings as SettingsState,
} from '../settings/store'

interface SettingsProps {
  lang: Lang
  settings: SettingsState
  onChange: (s: SettingsState) => void
  onBack: () => void
}

export function SettingsScreen({ lang, settings, onChange, onBack }: SettingsProps) {
  const [kgMsg, setKgMsg] = useState('')
  const [kgBusy, setKgBusy] = useState(false)
  const [connected, setConnected] = useState(() => isKataGoAvailable())
  const [health, setHealth] = useState<BridgeHealth | null>(null)
  const [compute, setCompute] = useState<ComputeHint | null>(null)

  useEffect(() => {
    void probeBridge(settings.katagoBridgeUrl).then(setHealth)
  }, [settings.katagoBridgeUrl])

  useEffect(() => {
    void detectComputeHint().then(setCompute)
  }, [])

  async function onConnect() {
    setKgBusy(true)
    setKgMsg('')
    const h = await probeBridge(settings.katagoBridgeUrl)
    setHealth(h)
    if (!h) {
      setKgMsg('브리지 없음 — npm run katago:bridge 를 먼저 실행하세요.')
      setKgBusy(false)
      return
    }
    if (h.defaults && h.defaults.hasModel === false && !settings.katagoModel) {
      setKgMsg('모델 파일 없음 — katago/models/ 에 .bin.gz 를 넣으세요.')
      setKgBusy(false)
      return
    }
    const r = await connectBridge(settings.katagoBridgeUrl, {
      exe: settings.katagoExe || undefined,
      model: settings.katagoModel || undefined,
      config: settings.katagoConfig || undefined,
    })
    setConnected(r.ok)
    setKgMsg(r.ok ? t(lang, 'katagoOn') : `실패: ${r.error}`)
    setKgBusy(false)
  }

  function onDisconnect() {
    disconnectBridge()
    setConnected(false)
    setKgMsg(t(lang, 'katagoOff'))
  }

  return (
    <section className="screen">
      <header className="screen-head">
        <h2>{t(lang, 'settings')}</h2>
        <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
      </header>

      <fieldset className="field">
        <legend>{t(lang, 'goRules')}</legend>
        <label className="radio">
          <input
            type="radio"
            checked={settings.goRules === 'japanese'}
            onChange={() => onChange({ ...settings, goRules: 'japanese' })}
          />
          {t(lang, 'rulesJapanese')}
        </label>
        <label className="radio">
          <input
            type="radio"
            checked={settings.goRules === 'chinese'}
            onChange={() => onChange({ ...settings, goRules: 'chinese' })}
          />
          {t(lang, 'rulesChinese')}
        </label>
      </fieldset>

      <label className="field">
        <span>{t(lang, 'language')}</span>
        <select
          value={settings.lang}
          onChange={(e) => onChange({ ...settings, lang: e.target.value as Lang })}
        >
          {(Object.keys(LANG_LABELS) as Lang[]).map((l) => (
            <option key={l} value={l}>{LANG_LABELS[l]}</option>
          ))}
        </select>
      </label>

      <label className="field">
        <span>{t(lang, 'font')}</span>
        <select
          value={settings.font}
          onChange={(e) => onChange({ ...settings, font: e.target.value as FontId })}
          style={{ fontFamily: FONT_OPTIONS.find((f) => f.id === settings.font)?.css }}
        >
          {FONT_OPTIONS.map((f) => (
            <option key={f.id} value={f.id} style={{ fontFamily: f.css }}>
              {f.label}
            </option>
          ))}
        </select>
      </label>

      <fieldset className="field">
        <legend>{t(lang, 'fontSize')}</legend>
        {(
          [
            ['small', 'sizeSmall'],
            ['medium', 'sizeMedium'],
            ['large', 'sizeLarge'],
          ] as const
        ).map(([id, key]) => (
          <label key={id} className="radio">
            <input
              type="radio"
              checked={settings.fontSize === id}
              onChange={() => onChange({ ...settings, fontSize: id as FontSizeId })}
            />
            {t(lang, key)}
          </label>
        ))}
      </fieldset>

      <label className="check">
        <input
          type="checkbox"
          checked={settings.blinkIntersections}
          onChange={(e) => onChange({ ...settings, blinkIntersections: e.target.checked })}
        />
        {settings.blinkIntersections ? t(lang, 'blinkOn') : t(lang, 'blinkOff')}
      </label>

      <label className="check">
        <input
          type="checkbox"
          checked={settings.maxContrastBoard}
          onChange={(e) => onChange({ ...settings, maxContrastBoard: e.target.checked })}
        />
        {t(lang, 'highContrast')}
      </label>

      <label className="check">
        <input
          type="checkbox"
          checked={settings.strongButtonContrast}
          onChange={(e) => onChange({ ...settings, strongButtonContrast: e.target.checked })}
        />
        {t(lang, 'strongButtonContrast')}
      </label>

      {settings.strongButtonContrast && (
        <div className="contrast-preview" aria-label={t(lang, 'strongButtonContrast')}>
          <button type="button" className="btn btn-primary" tabIndex={-1}>
            {t(lang, 'startGame')}
          </button>
          <button type="button" className="btn" tabIndex={-1}>
            {t(lang, 'review')}
          </button>
          <button type="button" className="btn btn-danger" tabIndex={-1}>
            {t(lang, 'resign')}
          </button>
        </div>
      )}

      <label className="check">
        <input
          type="checkbox"
          checked={settings.reduceMotion}
          onChange={(e) => onChange({ ...settings, reduceMotion: e.target.checked })}
        />
        {t(lang, 'reduceMotionLabel')}
      </label>

      <label className="check">
        <input
          type="checkbox"
          checked={settings.moveSound}
          onChange={(e) => {
            const on = e.target.checked
            onChange({ ...settings, moveSound: on })
            if (on) playMoveSound(true)
          }}
        />
        {settings.moveSound ? t(lang, 'moveSoundOn') : t(lang, 'moveSoundOff')}
      </label>

      <fieldset className="field">
        <legend>{t(lang, 'boardScale')}</legend>
        {(
          [
            ['small', 'sizeSmall'],
            ['medium', 'sizeMedium'],
            ['large', 'sizeLarge'],
          ] as const
        ).map(([id, key]) => (
          <label key={id} className="radio">
            <input
              type="radio"
              checked={settings.boardScale === id}
              onChange={() => onChange({ ...settings, boardScale: id as BoardScaleId })}
            />
            {t(lang, key)}
          </label>
        ))}
      </fieldset>

      <fieldset className="field">
        <legend>{t(lang, 'lineWeight')}</legend>
        {(
          [
            ['thin', 'lineThin'],
            ['normal', 'lineNormal'],
            ['thick', 'lineThick'],
          ] as const
        ).map(([id, key]) => (
          <label key={id} className="radio">
            <input
              type="radio"
              checked={settings.lineWeight === id}
              onChange={() => onChange({ ...settings, lineWeight: id as LineWeightId })}
            />
            {t(lang, key)}
          </label>
        ))}
      </fieldset>

      <details className="details" open>
        <summary>{t(lang, 'katagoStatus')}</summary>
        <p className="meta">{connected ? t(lang, 'katagoOn') : t(lang, 'katagoOff')}</p>
        {compute && (
          <p className="meta" role="status">
            {t(lang, 'computeDetect')}:{' '}
            <span className="mono">
              [{compute.kind.toUpperCase()}] {compute.detail}
            </span>
          </p>
        )}
        {health && (
          <p className="meta mono" role="status">
            bridge {health.running ? 'running' : 'idle'}
            {health.platform ? ` · ${health.platform.os}/${health.platform.arch}` : ''}
            {health.defaults
              ? ` · exe:${health.defaults.hasExe ? 'OK' : 'missing'} model:${health.defaults.hasModel ? 'OK' : 'missing'}`
              : ''}
          </p>
        )}
        {kgMsg && <p className={connected ? 'done-msg' : 'error'} role="status">{kgMsg}</p>}
        <label className="field">
          <span>{t(lang, 'katagoBridge')}</span>
          <input
            className="mono"
            value={settings.katagoBridgeUrl}
            onChange={(e) => onChange({ ...settings, katagoBridgeUrl: e.target.value })}
          />
        </label>
        <p className="hint">{t(lang, 'katagoPathHint')}</p>
        <label className="field">
          <span>katago.exe</span>
          <input
            className="mono"
            value={settings.katagoExe}
            onChange={(e) => onChange({ ...settings, katagoExe: e.target.value })}
            placeholder="katago/bin/katago.exe"
          />
        </label>
        <label className="field">
          <span>model</span>
          <input
            className="mono"
            value={settings.katagoModel}
            onChange={(e) => onChange({ ...settings, katagoModel: e.target.value })}
            placeholder="katago/models/*.bin.gz"
          />
        </label>
        <label className="field">
          <span>config</span>
          <input
            className="mono"
            value={settings.katagoConfig}
            onChange={(e) => onChange({ ...settings, katagoConfig: e.target.value })}
            placeholder="katago/default_gtp.cfg"
          />
        </label>
        <label className="check">
          <input
            type="checkbox"
            checked={settings.katagoAutoConnect}
            onChange={(e) => onChange({ ...settings, katagoAutoConnect: e.target.checked })}
          />
          {t(lang, 'katagoAuto')}
        </label>
        <div className="btn-row">
          <button type="button" className="btn btn-primary" disabled={kgBusy} onClick={onConnect}>
            {t(lang, 'katagoConnect')}
          </button>
          <button type="button" className="btn" onClick={onDisconnect}>
            {t(lang, 'katagoDisconnect')}
          </button>
        </div>
        <pre className="mono hint-block">{KATAGO_SETUP_HINT}</pre>
      </details>

      <details className="details" open>
        <summary>{t(lang, 'history')}</summary>
        <ol className="changelog">
          {CHANGELOG.map((e) => (
            <li key={e.version}>
              <h4 className="mono">v{e.version} <span>{e.date}</span></h4>
              <ul>
                {e.lines.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </li>
          ))}
        </ol>
      </details>
    </section>
  )
}
