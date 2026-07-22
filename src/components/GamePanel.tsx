import { pointLabel } from '../engine/board'
import type { GameState, Player } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface GamePanelProps {
  lang: Lang
  state: GameState
  statusText: string
  onPass: () => void
  onResign: () => void
  onBack: () => void
}

export function GamePanel({ lang, state, statusText, onPass, onResign, onBack }: GamePanelProps) {
  const last = state.history[state.history.length - 1]
  const turnLabel = state.toPlay === 1 ? t(lang, 'black') : t(lang, 'white')

  return (
    <aside className="panel" aria-live="polite">
      <p className="status-line">{statusText}</p>
      <p className="meta mono">
        {turnLabel} · {state.ended ? t(lang, 'gameOver') : t(lang, 'yourTurn')}
      </p>
      <dl className="stats">
        <div>
          <dt>{t(lang, 'black')} {t(lang, 'captures')}</dt>
          <dd className="mono">{state.captures[1 as Player]}</dd>
        </div>
        <div>
          <dt>{t(lang, 'white')} {t(lang, 'captures')}</dt>
          <dd className="mono">{state.captures[2 as Player]}</dd>
        </div>
        <div>
          <dt>{t(lang, 'lastMove')}</dt>
          <dd className="mono">
            {last
              ? last.pass
                ? t(lang, 'pass')
                : pointLabel(last.x, last.y)
              : '—'}
          </dd>
        </div>
      </dl>
      <div className="btn-row">
        <button type="button" className="btn" onClick={onPass} disabled={state.ended}>
          {t(lang, 'pass')}
        </button>
        <button type="button" className="btn btn-danger" onClick={onResign} disabled={state.ended}>
          {t(lang, 'resign')}
        </button>
        <button type="button" className="btn" onClick={onBack}>
          {t(lang, 'back')}
        </button>
      </div>
    </aside>
  )
}
