import { KATAGO_SETUP_HINT } from '../ai/katago'
import { CHANGELOG } from '../history/changelog'
import { LANG_LABELS, type Lang, t } from '../i18n/dict'
import {
  FONT_OPTIONS,
  type FontId,
  type FontSizeId,
  type Settings as SettingsState,
} from '../settings/store'

interface SettingsProps {
  lang: Lang
  settings: SettingsState
  onChange: (s: SettingsState) => void
  onBack: () => void
}

export function SettingsScreen({ lang, settings, onChange, onBack }: SettingsProps) {
  return (
    <section className="screen">
      <header className="screen-head">
        <h2>{t(lang, 'settings')}</h2>
        <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
      </header>

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
          checked={settings.reduceMotion}
          onChange={(e) => onChange({ ...settings, reduceMotion: e.target.checked })}
        />
        움직임 줄이기 (깜빡임 정지)
      </label>

      <details className="details">
        <summary>{t(lang, 'katagoStatus')}</summary>
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
