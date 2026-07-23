import { useRef } from 'react'
import { pointLabel } from '../engine/board'
import { estimateScore, type GoRules } from '../engine/scoring'
import type { GameState, Player } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { downloadSgf, encodeSgf } from '../sgf/sgf'

interface GamePanelProps {
  lang: Lang
  state: GameState
  statusText: string
  reviewPly?: number
  reviewLen?: number
  goRules?: GoRules
  onPass: () => void
  onResign: () => void
  onBack: () => void
  onLoadSgf?: (text: string) => void
  onUndo?: () => void
  onRedo?: () => void
  onHint?: () => void
  hintDisabled?: boolean
}

export function GamePanel({
  lang,
  state,
  statusText,
  reviewPly,
  reviewLen,
  goRules = 'japanese',
  onPass,
  onResign,
  onBack,
  onLoadSgf,
  onUndo,
  onRedo,
  onHint,
  hintDisabled,
}: GamePanelProps) {
  const fileRef = useRef<HTMLInputElement>(null)
  const last = state.history[state.history.length - 1]
  const turnLabel = state.toPlay === 1 ? t(lang, 'black') : t(lang, 'white')
  const liveScore = estimateScore(state, goRules)
  const score = state.ended ? liveScore : null
  const resultLabel = score
    ? `${
        score.winner === 1
          ? t(lang, 'blackWins')
          : score.winner === 2
            ? t(lang, 'whiteWins')
            : t(lang, 'draw')
      }${state.resignedBy ? ` (${t(lang, 'resignWin')})` : ''}`
    : ''

  function save() {
    const sgf = encodeSgf(state, { black: 'Black', white: 'White' })
    const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-')
    downloadSgf(`svil-baduk-${state.size}-${stamp}.sgf`, sgf)
  }

  const lastCoord = last
    ? last.pass
      ? t(lang, 'pass')
      : pointLabel(last.x, last.y)
    : '—'

  return (
    <aside className="panel" aria-live="polite">
      <header className="panel-head">
        <p className="status-line">{statusText}</p>
        <p className="meta mono">
          {turnLabel}
          {state.ended ? ` · ${t(lang, 'gameOver')}` : ` · ${t(lang, 'yourTurn')}`}
          {reviewLen != null && reviewPly != null ? ` · ${t(lang, 'review')} ${reviewPly}/${reviewLen}` : ''}
        </p>
      </header>

      <div className="last-move-box" role="status" aria-label={t(lang, 'lastMove')}>
        <span className="last-move-label">{t(lang, 'lastMove')}</span>
        <span className="last-move-coord mono">{lastCoord}</span>
      </div>

      <dl className="stats stats-live">
        <div>
          <dt>{t(lang, 'black')} {t(lang, 'territory')}</dt>
          <dd className="mono">{liveScore.blackTerritory}</dd>
        </div>
        <div>
          <dt>{t(lang, 'white')} {t(lang, 'territory')}</dt>
          <dd className="mono">{liveScore.whiteTerritory}</dd>
        </div>
        <div>
          <dt>{t(lang, 'black')} {t(lang, 'total')}</dt>
          <dd className="mono">{liveScore.blackTotal}</dd>
        </div>
        <div>
          <dt>{t(lang, 'white')} {t(lang, 'total')}</dt>
          <dd className="mono">{liveScore.whiteTotal}</dd>
        </div>
        <div>
          <dt>{t(lang, 'black')} {t(lang, 'captures')}</dt>
          <dd className="mono">{state.captures[1 as Player]}</dd>
        </div>
        <div>
          <dt>{t(lang, 'white')} {t(lang, 'captures')}</dt>
          <dd className="mono">{state.captures[2 as Player]}</dd>
        </div>
      </dl>
      <p className="hint score-live-note">{t(lang, 'liveScoreNote')}</p>

      {score && (
        <section className="score-box" aria-label={t(lang, 'score')}>
          <h3 className="score-title">{t(lang, 'score')} — {resultLabel}</h3>
          <dl className="stats">
            <div>
              <dt>{t(lang, 'goRules')}</dt>
              <dd>{score.rules === 'chinese' ? t(lang, 'rulesChinese') : t(lang, 'rulesJapanese')}</dd>
            </div>
            <div>
              <dt>{t(lang, 'komi')} ({t(lang, 'white')})</dt>
              <dd className="mono">{score.komi}</dd>
            </div>
          </dl>
          <p className="hint">{t(lang, 'scoreNote')}</p>
        </section>
      )}

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

      {onHint && (
        <div className="btn-row">
          <button type="button" className="btn btn-primary" onClick={onHint} disabled={hintDisabled}>
            {t(lang, 'askHint')}
          </button>
        </div>
      )}

      <div className="btn-row">
        <button type="button" className="btn" onClick={save}>
          {t(lang, 'saveSgf')}
        </button>
        {onLoadSgf && (
          <>
            <button type="button" className="btn" onClick={() => fileRef.current?.click()}>
              {t(lang, 'loadSgf')}
            </button>
            <input
              ref={fileRef}
              type="file"
              accept=".sgf,application/x-go-sgf,text/plain"
              hidden
              onChange={async (e) => {
                const file = e.target.files?.[0]
                if (!file) return
                const text = await file.text()
                onLoadSgf(text)
                e.target.value = ''
              }}
            />
          </>
        )}
      </div>

      {(onUndo || onRedo) && (
        <div className="btn-row">
          <button type="button" className="btn" onClick={onUndo} disabled={!onUndo || (reviewPly ?? 0) <= 0}>
            {t(lang, 'undoMove')}
          </button>
          <button
            type="button"
            className="btn"
            onClick={onRedo}
            disabled={!onRedo || reviewPly == null || reviewLen == null || reviewPly >= reviewLen}
          >
            {t(lang, 'redoMove')}
          </button>
        </div>
      )}
    </aside>
  )
}
