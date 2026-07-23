import { useEffect, useMemo, useState } from 'react'
import { pickBuiltinMove } from '../ai/builtin'
import { isKataGoAvailable, katagoGenmove } from '../ai/katago'
import { DEFAULT_RANK, RANKS, getRank, rankLabel, type RankId } from '../ai/ranks'
import { playMoveSound } from '../audio/moveSound'
import { Board } from '../components/Board'
import { GamePanel } from '../components/GamePanel'
import { MoveAnnouncer } from '../components/MoveAnnouncer'
import { createGame, tryPlay, pass, resign } from '../engine/board'
import { estimateScore } from '../engine/scoring'
import type { BoardSize, GameState, Move, Player, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { BOARD_CELL_PX, LINE_STROKE, type Settings } from '../settings/store'
import { decodeSgf, replayTo } from '../sgf/sgf'

interface SoloProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

export function Solo({ lang, settings, onBack }: SoloProps) {
  const [phase, setPhase] = useState<'setup' | 'play'>('setup')
  const [size, setSize] = useState<BoardSize>(9)
  const [rankId, setRankId] = useState<RankId>(DEFAULT_RANK)
  const [myColor, setMyColor] = useState<Player>(1)
  const [live, setLive] = useState<GameState>(() => createGame(9))
  const [tree, setTree] = useState<Move[] | null>(null)
  const [ply, setPly] = useState(0)
  const [error, setError] = useState('')
  const [aiBusy, setAiBusy] = useState(false)
  const [hintPts, setHintPts] = useState<Point[]>([])
  const [hintBusy, setHintBusy] = useState(false)

  const reviewing = tree !== null && ply < tree.length
  const state = useMemo(
    () => (tree ? replayTo(tree, size, ply) : live),
    [tree, size, ply, live],
  )

  const lastMove: Point | null =
    state.history.length && !state.history[state.history.length - 1].pass
      ? {
          x: state.history[state.history.length - 1].x,
          y: state.history[state.history.length - 1].y,
        }
      : null

  const atTip = !tree || ply === tree.length
  const humanTurn = phase === 'play' && atTip && !state.ended && state.toPlay === myColor
  const ownership = state.ended ? estimateScore(state).ownership : undefined

  useEffect(() => {
    if (phase !== 'play') return
    const onKey = (e: KeyboardEvent) => {
      const tag = (e.target as HTMLElement | null)?.tagName
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
      // 보드 화살표 착수와 충돌 방지 — z/x 로 복기
      if (e.key === 'z' || e.key === 'Z') {
        e.preventDefault()
        onUndo()
      } else if (e.key === 'x' || e.key === 'X') {
        e.preventDefault()
        onRedo()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase, tree, ply, live.history.length])

  useEffect(() => {
    if (phase !== 'play' || !atTip || state.ended || state.toPlay === myColor || aiBusy) return
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
        if (r.ok) commitLive(r.state)
      } else {
        const r = tryPlay(state, move.x, move.y)
        if (r.ok) {
          commitLive(r.state)
          playMoveSound(settings.moveSound)
        } else {
          const r2 = pass(state)
          if (r2.ok) commitLive(r2.state)
        }
      }
      setAiBusy(false)
    })()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase, state, myColor, rankId, aiBusy, settings.moveSound, atTip])

  function commitLive(next: GameState) {
    setLive(next)
    setTree(null)
    setPly(next.history.length)
    setHintPts([])
  }

  function start() {
    const g = createGame(size)
    setLive(g)
    setTree(null)
    setPly(0)
    setError('')
    setPhase('play')
    setAiBusy(false)
  }

  function onPlay(x: number, y: number) {
    if (!humanTurn || aiBusy) return
    const base = atTip ? state : replayTo(tree!, size, ply)
    const r = tryPlay(base, x, y)
    if (!r.ok) {
      setError(r.reason === 'superko' || r.reason === 'ko' ? t(lang, 'superko') : t(lang, 'illegal'))
      return
    }
    setError('')
    commitLive(r.state)
    playMoveSound(settings.moveSound)
  }

  function onUndo() {
    const moves = tree ?? live.history
    if (moves.length === 0) return
    const nextPly = Math.max(0, (tree ? ply : moves.length) - 1)
    setTree(moves)
    setPly(nextPly)
  }

  function onRedo() {
    if (!tree) return
    setPly((p) => Math.min(tree.length, p + 1))
  }


  function onLoadSgf(text: string) {
    const loaded = decodeSgf(text)
    if (!loaded.ok) {
      setError(t(lang, 'sgfFailed'))
      return
    }
    setSize(loaded.size)
    setLive(loaded.state)
    setTree(loaded.state.history)
    setPly(loaded.state.history.length)
    setError('')
    setPhase('play')
    setAiBusy(false)
    setHintPts([])
  }

  async function onHint() {
    if (!atTip || state.ended || hintBusy || aiBusy) return
    setHintBusy(true)
    setError('')
    try {
      let move: Point | 'pass' | null = null
      if (isKataGoAvailable()) {
        move = await katagoGenmove(state, rankId)
      }
      if (!move || move === 'pass') {
        const p = pickBuiltinMove(state, rankId)
        move = move === 'pass' ? 'pass' : (p ?? 'pass')
      }
      if (move === 'pass') {
        setHintPts([])
        setError(t(lang, 'hintPass'))
      } else {
        setHintPts([move])
        setError(t(lang, 'hintReady'))
      }
    } finally {
      setHintBusy(false)
    }
  }

  if (phase === 'setup') {
    const rank = getRank(rankId)
    return (
      <section className="screen solo-setup">
        <header className="screen-head">
          <h2>{t(lang, 'solo')}</h2>
          <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
        </header>
        <p className="solo-lead">{t(lang, 'soloLead')}</p>
        <div className="ai-status" role="status">
          <p>
            {t(lang, 'opponentSummary')}: {rankLabel(rankId, lang)}
            {' · '}
            {isKataGoAvailable()
              ? `${t(lang, 'aiEngineKatago')} ${rank.visits})`
              : t(lang, 'aiEngineBuiltin')}
          </p>
          <p className="hint">
            {isKataGoAvailable()
              ? t(lang, 'katagoOn')
              : `${t(lang, 'katagoOff')} — npm run katago:bridge`}
          </p>
        </div>
        <fieldset className="field">
          <legend>{t(lang, 'difficulty')} (1–10)</legend>
          <div className="diff-level-row" role="group" aria-label={t(lang, 'difficulty')}>
            {RANKS.map((r) => (
              <button
                key={r.id}
                type="button"
                className={`btn diff-level${rankId === r.id ? ' diff-level-on' : ''}`}
                aria-pressed={rankId === r.id}
                onClick={() => setRankId(r.id)}
              >
                <span className="diff-level-num">{r.level}</span>
                <span className="diff-level-name">{lang === 'ko' ? r.labelKo.split(' · ')[1] : r.labelEn.split(' · ')[1]}</span>
              </button>
            ))}
          </div>
        </fieldset>
        <label className="field">
          <span>{t(lang, 'boardSize')}</span>
          <select value={size} onChange={(e) => setSize(Number(e.target.value) as BoardSize)}>
            <option value={9}>9×9</option>
            <option value={13}>13×13</option>
            <option value={19}>19×19</option>
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
        <div className="btn-row">
          <button type="button" className="btn btn-primary" onClick={start}>
            {t(lang, 'startGame')}
          </button>
          <label className="btn">
            {t(lang, 'loadSgf')}
            <input
              type="file"
              accept=".sgf,application/x-go-sgf,text/plain"
              hidden
              onChange={async (e) => {
                const f = e.target.files?.[0]
                if (!f) return
                onLoadSgf(await f.text())
              }}
            />
          </label>
        </div>
      </section>
    )
  }

  const status = reviewing
    ? `${t(lang, 'review')} ${ply}/${tree!.length}`
    : state.ended
      ? `${t(lang, 'gameOver')} · ${t(lang, 'score')}`
      : aiBusy
        ? t(lang, 'aiTurn')
        : humanTurn
          ? t(lang, 'yourTurn')
          : t(lang, 'aiTurn')

  const reviewLen = tree?.length ?? live.history.length
  const reviewPly = tree ? ply : live.history.length

  return (
    <section className="screen game-screen">
      <p className="sr-help">{t(lang, 'blinkHelp')} · {t(lang, 'review')}: Z / X</p>
      <MoveAnnouncer lang={lang} state={state} />
      {error && <p className="error" role="alert">{error}</p>}
      {state.ended && (
        <p className="hint" role="note">
          집 표시: <span className="territory-b">흑집</span> / <span className="territory-w">백집</span> (공배는 표시 없음)
        </p>
      )}
      <div className="game-layout">
        <Board
          state={state}
          interactive={humanTurn && !aiBusy}
          blink={settings.blinkIntersections}
          maxContrast={settings.maxContrastBoard}
          reduceMotion={settings.reduceMotion}
          lastMove={lastMove}
          ownership={ownership}
          markers={hintPts}
          cellSize={BOARD_CELL_PX[settings.boardScale]}
          lineWidth={LINE_STROKE[settings.lineWeight]}
          onPlay={onPlay}
          ariaLabel={`${t(lang, 'solo')} ${size}×${size}`}
        />
        <GamePanel
          lang={lang}
          state={state}
          statusText={hintBusy ? t(lang, 'hintBusy') : status}
          reviewPly={reviewPly}
          reviewLen={reviewLen}
          onPass={() => {
            if (!humanTurn) return
            const r = pass(state)
            if (r.ok) commitLive(r.state)
          }}
          onResign={() => commitLive(resign(state, myColor))}
          onBack={() => setPhase('setup')}
          onLoadSgf={onLoadSgf}
          onUndo={onUndo}
          onRedo={onRedo}
          onHint={onHint}
          hintDisabled={!humanTurn || hintBusy || aiBusy || state.ended}
        />
      </div>
    </section>
  )
}
