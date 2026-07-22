import { useEffect, useState } from 'react'
import { pickBuiltinMove } from '../ai/builtin'
import { isKataGoAvailable, katagoGenmove } from '../ai/katago'
import { RANKS, type RankId } from '../ai/ranks'
import { Board } from '../components/Board'
import { GamePanel } from '../components/GamePanel'
import { createGame, tryPlay, pass } from '../engine/board'
import type { BoardSize, GameState, Player, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import type { Settings } from '../settings/store'

interface SoloProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

export function Solo({ lang, settings, onBack }: SoloProps) {
  const [phase, setPhase] = useState<'setup' | 'play'>('setup')
  const [size, setSize] = useState<BoardSize>(9)
  const [rankId, setRankId] = useState<RankId>('20k')
  const [myColor, setMyColor] = useState<Player>(1)
  const [state, setState] = useState<GameState>(() => createGame(9))
  const [error, setError] = useState('')
  const [aiBusy, setAiBusy] = useState(false)

  const lastMove: Point | null =
    state.history.length && !state.history[state.history.length - 1].pass
      ? {
          x: state.history[state.history.length - 1].x,
          y: state.history[state.history.length - 1].y,
        }
      : null

  const humanTurn = !state.ended && state.toPlay === myColor

  useEffect(() => {
    if (phase !== 'play' || state.ended || state.toPlay === myColor || aiBusy) return
    let cancelled = false
    ;(async () => {
      setAiBusy(true)
      await new Promise((r) => setTimeout(r, 280))
      if (cancelled) return
      let move: Point | 'pass' | null = null
      if (isKataGoAvailable()) {
        move = await katagoGenmove(state, rankId)
      }
      if (!move) {
        const p = pickBuiltinMove(state, rankId)
        move = p ?? 'pass'
      }
      if (cancelled) return
      if (move === 'pass') {
        const r = pass(state)
        if (r.ok) setState(r.state)
      } else {
        const r = tryPlay(state, move.x, move.y)
        if (r.ok) setState(r.state)
        else {
          const r2 = pass(state)
          if (r2.ok) setState(r2.state)
        }
      }
      setAiBusy(false)
    })()
    return () => {
      cancelled = true
    }
  }, [phase, state, myColor, rankId, aiBusy])

  function start() {
    setState(createGame(size))
    setError('')
    setPhase('play')
    setAiBusy(false)
  }

  function onPlay(x: number, y: number) {
    if (!humanTurn || aiBusy) return
    const r = tryPlay(state, x, y)
    if (!r.ok) {
      setError(t(lang, 'illegal'))
      return
    }
    setError('')
    setState(r.state)
  }

  if (phase === 'setup') {
    return (
      <section className="screen">
        <header className="screen-head">
          <h2>{t(lang, 'solo')}</h2>
          <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
        </header>
        <p className="ai-status">
          {isKataGoAvailable() ? t(lang, 'katagoStatus') + ': ON' : t(lang, 'katagoOff')}
        </p>
        <label className="field">
          <span>{t(lang, 'boardSize')}</span>
          <select value={size} onChange={(e) => setSize(Number(e.target.value) as BoardSize)}>
            <option value={9}>9×9</option>
            <option value={13}>13×13</option>
            <option value={19}>19×19</option>
          </select>
        </label>
        <label className="field">
          <span>{t(lang, 'rank')}</span>
          <select value={rankId} onChange={(e) => setRankId(e.target.value as RankId)}>
            {RANKS.map((r) => (
              <option key={r.id} value={r.id}>{r.labelKo}</option>
            ))}
          </select>
        </label>
        <fieldset className="field">
          <legend>{t(lang, 'playAs')}</legend>
          <label className="radio">
            <input type="radio" checked={myColor === 1} onChange={() => setMyColor(1)} />
            {t(lang, 'black')}
          </label>
          <label className="radio">
            <input type="radio" checked={myColor === 2} onChange={() => setMyColor(2)} />
            {t(lang, 'white')}
          </label>
        </fieldset>
        <button type="button" className="btn btn-primary" onClick={start}>
          {t(lang, 'startGame')}
        </button>
      </section>
    )
  }

  const status = state.ended
    ? t(lang, 'gameOver')
    : aiBusy
      ? t(lang, 'aiTurn')
      : humanTurn
        ? t(lang, 'yourTurn')
        : t(lang, 'aiTurn')

  return (
    <section className="screen game-screen">
      <p className="sr-help">{t(lang, 'blinkHelp')}</p>
      {error && <p className="error" role="alert">{error}</p>}
      <div className="game-layout">
        <Board
          state={state}
          interactive={humanTurn && !aiBusy}
          blink={settings.blinkIntersections}
          maxContrast={settings.maxContrastBoard}
          reduceMotion={settings.reduceMotion}
          lastMove={lastMove}
          onPlay={onPlay}
          ariaLabel={`${t(lang, 'solo')} ${size}×${size}`}
        />
        <GamePanel
          lang={lang}
          state={state}
          statusText={status}
          onPass={() => {
            if (!humanTurn) return
            const r = pass(state)
            if (r.ok) setState(r.state)
          }}
          onResign={() => setState({ ...state, ended: true })}
          onBack={() => setPhase('setup')}
        />
      </div>
    </section>
  )
}
