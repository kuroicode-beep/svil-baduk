import { useEffect, useMemo, useRef, useState } from 'react'
import { pickBuiltinMove, pickBuiltinTopMoves } from '../ai/builtin'
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
import { recordSoloResult } from '../profile/progress'
import { hasCharacter, loadProfile, saveProfile } from '../profile/store'
import { enterFullscreen, exitFullscreen } from '../platform/fullscreen'
import { BOARD_CELL_PX, LINE_STROKE, type Settings } from '../settings/store'
import { decodeSgf, replayTo } from '../sgf/sgf'
import { clearSoloSnapshot, loadSoloSnapshot, saveSoloSnapshot } from '../solo/snapshot'

const SOLO_PREFS_KEY = 'svil-baduk-solo-prefs'

type SoloPrefs = { rankId: RankId; size: BoardSize; myColor: Player }

function loadSoloPrefs(): SoloPrefs {
  try {
    const raw = localStorage.getItem(SOLO_PREFS_KEY)
    if (!raw) return { rankId: DEFAULT_RANK, size: 9, myColor: 1 }
    const p = JSON.parse(raw) as Partial<SoloPrefs>
    const rankId = RANKS.some((r) => r.id === p.rankId) ? (p.rankId as RankId) : DEFAULT_RANK
    const size = ([9, 13, 19] as BoardSize[]).includes(p.size as BoardSize)
      ? (p.size as BoardSize)
      : 9
    const myColor = p.myColor === 2 ? 2 : 1
    return { rankId, size, myColor }
  } catch {
    return { rankId: DEFAULT_RANK, size: 9, myColor: 1 }
  }
}

function saveSoloPrefs(p: SoloPrefs) {
  localStorage.setItem(SOLO_PREFS_KEY, JSON.stringify(p))
}

interface SoloProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

export function Solo({ lang, settings, onBack }: SoloProps) {
  const prefs = loadSoloPrefs()
  const [phase, setPhase] = useState<'setup' | 'play'>('setup')
  const [size, setSize] = useState<BoardSize>(prefs.size)
  const [rankId, setRankId] = useState<RankId>(prefs.rankId)
  const [myColor, setMyColor] = useState<Player>(prefs.myColor)
  const [live, setLive] = useState<GameState>(() => createGame(9))
  const [tree, setTree] = useState<Move[] | null>(null)
  const [ply, setPly] = useState(0)
  const [error, setError] = useState('')
  const [aiBusy, setAiBusy] = useState(false)
  const [hintPts, setHintPts] = useState<Array<Point & { label?: string }>>([])
  const [hintBusy, setHintBusy] = useState(false)
  const [progressNote, setProgressNote] = useState('')
  const [snapshotMeta, setSnapshotMeta] = useState(() => loadSoloSnapshot())
  const recordedEndRef = useRef(false)
  /** AI 착수 요청 세대 — aiBusy를 deps에 넣으면 setAiBusy(true)가 effect를 취소해 영구 정지됨 */
  const aiTurnGenRef = useRef(0)

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
  const lastWasOpponent =
    !!state.history.length && state.history[state.history.length - 1].player !== myColor
  const blinkLastMove = humanTurn && lastWasOpponent && !!lastMove
  const ownership = state.ended
    ? estimateScore(state, settings.goRules).ownership
    : undefined

  function persistSnapshot(next: GameState, opts?: { size?: BoardSize; rankId?: RankId; myColor?: Player }) {
    saveSoloSnapshot({
      size: opts?.size ?? size,
      rankId: opts?.rankId ?? rankId,
      myColor: opts?.myColor ?? myColor,
      state: next,
    })
    setSnapshotMeta(loadSoloSnapshot())
  }

  useEffect(() => {
    if (phase === 'play') {
      void enterFullscreen()
    } else {
      void exitFullscreen()
    }
    return () => {
      void exitFullscreen()
    }
  }, [phase])

  useEffect(() => {
    if (phase !== 'play') return
    const onKey = (e: KeyboardEvent) => {
      const tag = (e.target as HTMLElement | null)?.tagName
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
      // 보드 화살표 착수와 충돌 방지 — z/x 로 복기, h 로 힌트
      if (e.key === 'z' || e.key === 'Z') {
        e.preventDefault()
        onUndo()
      } else if (e.key === 'x' || e.key === 'X') {
        e.preventDefault()
        onRedo()
      } else if (e.key === 'h' || e.key === 'H') {
        e.preventDefault()
        void onHint()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase, tree, ply, live.history.length, humanTurn, aiBusy, hintBusy, rankId])

  useEffect(() => {
    if (phase !== 'play' || !atTip || state.ended || state.toPlay === myColor) return

    const gen = ++aiTurnGenRef.current
    const snapshot = state
    const snapRank = rankId
    const snapSound = settings.moveSound
    setAiBusy(true)

    ;(async () => {
      try {
        await new Promise((r) => setTimeout(r, 120))
        if (gen !== aiTurnGenRef.current) return

        let move: Point | 'pass' | null = null
        if (isKataGoAvailable()) {
          try {
            move = await katagoGenmove(snapshot, snapRank)
          } catch (e) {
            console.warn('[solo] katago genmove failed, falling back', e)
            move = null
          }
        }
        if (!move) {
          const p = pickBuiltinMove(snapshot, snapRank)
          move = p ?? 'pass'
        }
        if (gen !== aiTurnGenRef.current) return

        if (move === 'pass') {
          const r = pass(snapshot)
          if (r.ok) commitLive(r.state)
        } else {
          const r = tryPlay(snapshot, move.x, move.y)
          if (r.ok) {
            commitLive(r.state)
            playMoveSound(snapSound)
          } else {
            const r2 = pass(snapshot)
            if (r2.ok) commitLive(r2.state)
          }
        }
      } finally {
        if (gen === aiTurnGenRef.current) setAiBusy(false)
      }
    })()

    return () => {
      // 진행 중 요청 무효화 (언마운트·의존성 변경·Strict Mode 재실행)
      if (aiTurnGenRef.current === gen) aiTurnGenRef.current += 1
      setAiBusy(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase, state, myColor, rankId, settings.moveSound, atTip])

  function commitLive(next: GameState) {
    setLive(next)
    setTree(null)
    setPly(next.history.length)
    setHintPts([])
    persistSnapshot(next)
  }

  function start() {
    saveSoloPrefs({ rankId, size, myColor })
    const g = createGame(size)
    aiTurnGenRef.current += 1
    clearSoloSnapshot()
    setSnapshotMeta(null)
    setLive(g)
    setTree(null)
    setPly(0)
    setError('')
    setPhase('play')
    setAiBusy(false)
    setProgressNote('')
    recordedEndRef.current = false
    persistSnapshot(g)
    void enterFullscreen()
  }

  function resumeSnapshot() {
    const snap = loadSoloSnapshot()
    if (!snap) return
    saveSoloPrefs({ rankId: snap.rankId, size: snap.size, myColor: snap.myColor })
    aiTurnGenRef.current += 1
    setSize(snap.size)
    setRankId(snap.rankId)
    setMyColor(snap.myColor)
    setLive(snap.state)
    setTree(null)
    setPly(snap.state.history.length)
    setError('')
    setPhase('play')
    setAiBusy(false)
    setProgressNote('')
    recordedEndRef.current = snap.state.ended
    setSnapshotMeta(snap)
    void enterFullscreen()
  }

  function leaveToSetup() {
    if (phase === 'play') {
      persistSnapshot(live)
    }
    setPhase('setup')
    setSnapshotMeta(loadSoloSnapshot())
  }

  useEffect(() => {
    // 라이브 대국 종료만 반영 (SGF 복기 제외)
    if (phase !== 'play' || !live.ended || tree !== null || recordedEndRef.current) return
    recordedEndRef.current = true
    const profile = loadProfile()
    if (!hasCharacter(profile)) {
      setProgressNote(t(lang, 'profileNeedChar'))
      return
    }
    const score = estimateScore(live, settings.goRules)
    const myScore = myColor === 1 ? score.blackTotal : score.whiteTotal
    const result = recordSoloResult(profile, {
      myColor,
      winner: score.winner,
      myScore,
      rankId,
    })
    saveProfile(result.profile)
    const parts = [`${t(lang, 'profileXpGain')} +${result.xpGained}`]
    if (result.leveledUp > 0) {
      parts.push(`${t(lang, 'profileLevelUp')} → Lv.${result.profile.level}`)
    }
    if (result.newHighScore) parts.push(t(lang, 'profileNewHigh'))
    if (result.newBestAi) {
      parts.push(`${t(lang, 'profileBestAi')} ${result.profile.bestAiLevel}`)
    }
    setProgressNote(parts.join(' · '))
  }, [phase, live, tree, myColor, rankId, lang, settings.goRules])

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
    persistSnapshot(loaded.state, { size: loaded.size })
  }

  async function onHint() {
    if (!atTip || state.ended || hintBusy || aiBusy) return
    setHintBusy(true)
    setError('')
    try {
      let primary: Point | 'pass' | null = null
      if (isKataGoAvailable()) {
        primary = await katagoGenmove(state, rankId)
      }
      const top = pickBuiltinTopMoves(state, 3)
      if (primary && primary !== 'pass') {
        const rest = top
          .filter((m) => !(m.point.x === primary.x && m.point.y === primary.y))
          .slice(0, 2)
        setHintPts([
          { ...primary, label: '1·AI' },
          ...rest.map((m, i) => ({ ...m.point, label: `${i + 2}·${m.label.split('·')[1] ?? ''}` })),
        ])
        setError(t(lang, 'hintReady'))
      } else if (top.length > 0) {
        setHintPts(top.map((m) => ({ ...m.point, label: m.label })))
        setError(t(lang, 'hintReady'))
      } else {
        setHintPts([])
        setError(t(lang, 'hintPass'))
      }
    } finally {
      setHintBusy(false)
    }
  }

  if (phase === 'setup') {
    const rank = getRank(rankId)
    const profile = loadProfile()
    const hasChar = hasCharacter(profile)
    return (
      <section className="screen solo-setup">
        <header className="screen-head">
          <h2>{t(lang, 'solo')}</h2>
          <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
        </header>
        <p className="solo-lead">{t(lang, 'soloLead')}</p>
        <p className={`hint${hasChar ? '' : ' error'}`} role="status">
          {hasChar
            ? `${profile.name} · ${t(lang, 'profileLevel')} ${profile.level} · ${profile.wins}W/${profile.losses}L · ${t(lang, 'profileHighScore')} ${profile.highScore}`
            : t(lang, 'profileNeedChar')}
        </p>
        <div className="ai-status setup-strip" role="status">
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
        <div className="setup-grid">
          <fieldset className="field setup-panel">
            <legend>{t(lang, 'difficulty')} (1–10)</legend>
            <p className="setup-selected mono" aria-live="polite">
              Lv.{rank.level} · {lang === 'ko' ? rank.labelKo : rank.labelEn}
            </p>
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
          <div className="setup-side">
            <fieldset className="field setup-panel">
              <legend>{t(lang, 'boardSize')}</legend>
              <div className="size-pick" role="group" aria-label={t(lang, 'boardSize')}>
                {([9, 13, 19] as BoardSize[]).map((n) => (
                  <button
                    key={n}
                    type="button"
                    className={`btn size-pick-btn${size === n ? ' size-pick-on' : ''}`}
                    aria-pressed={size === n}
                    onClick={() => setSize(n)}
                  >
                    <span className="mono">{n}×{n}</span>
                  </button>
                ))}
              </div>
            </fieldset>
            <fieldset className="field setup-panel">
              <legend>{t(lang, 'playAs')}</legend>
              <div className="color-pick" role="group" aria-label={t(lang, 'playAs')}>
                <button
                  type="button"
                  className={`btn color-pick-btn${myColor === 1 ? ' color-pick-on' : ''}`}
                  aria-pressed={myColor === 1}
                  onClick={() => setMyColor(1)}
                >
                  {t(lang, 'black')}
                </button>
                <button
                  type="button"
                  className={`btn color-pick-btn${myColor === 2 ? ' color-pick-on' : ''}`}
                  aria-pressed={myColor === 2}
                  onClick={() => setMyColor(2)}
                >
                  {t(lang, 'white')}
                </button>
              </div>
            </fieldset>
          </div>
        </div>
        <div className="btn-row setup-actions">
          {snapshotMeta && (
            <button type="button" className="btn btn-primary" onClick={resumeSnapshot}>
              {t(lang, 'resumeGame')}
              <span className="nav-btn-sub mono">
                {snapshotMeta.size}×{snapshotMeta.size} · {snapshotMeta.state.history.length}
                {t(lang, 'movesShort')}
                {snapshotMeta.state.ended ? ` · ${t(lang, 'gameOver')}` : ''}
              </span>
            </button>
          )}
          <button type="button" className="btn btn-primary" onClick={start}>
            {snapshotMeta ? t(lang, 'newGame') : t(lang, 'startGame')}
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
      <p className="sr-help">
        {t(lang, 'blinkHelp')} · {t(lang, 'review')}: Z / X · {t(lang, 'askHint')}: H
      </p>
      <MoveAnnouncer lang={lang} state={state} />
      {hintPts.length > 0 && (
        <p className="sr-only" aria-live="polite" aria-atomic="true">
          {t(lang, 'askHint')}:{' '}
          {hintPts.map((p) => `${p.label ?? ''} ${p.x + 1},${p.y + 1}`).join(' · ')}
        </p>
      )}
      {error && <p className="error" role="alert">{error}</p>}
      {state.ended && (
        <p className="hint" role="note">
          집 표시: <span className="territory-b">흑집</span> / <span className="territory-w">백집</span> (공배는 표시 없음)
        </p>
      )}
      {progressNote && (
        <p className="done-msg" role="status">
          {progressNote}
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
          blinkLastMove={blinkLastMove}
          blackStone={settings.blackStone}
          whiteStone={settings.whiteStone}
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
          goRules={settings.goRules}
          onPass={() => {
            if (!humanTurn) return
            const r = pass(state)
            if (r.ok) commitLive(r.state)
          }}
          onResign={() => commitLive(resign(state, myColor))}
          onBack={leaveToSetup}
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
