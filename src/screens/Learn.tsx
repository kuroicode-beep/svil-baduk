// src/screens/Learn.tsx — 단계별 배우기 (트랙·스테이지·문제 진행 + XP 연동)
import { useMemo, useState } from 'react'
import { playMoveSound } from '../audio/moveSound'
import { Board } from '../components/Board'
import { tryPlay } from '../engine/board'
import type { GameState, Point } from '../engine/types'
import { problemState } from '../learn/boardSetup'
import { STAGES, stagesForTrack } from '../learn/curriculum'
import {
  isStageCleared,
  isStageUnlocked,
  loadLearnProgress,
  markSolved,
  saveLearnProgress,
  trackClearCount,
  type LearnProgress,
} from '../learn/progress'
import { loc, type LearnProblem, type LearnStage, type TrackId } from '../learn/types'
import type { DictKey, Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { recordLearnSolve } from '../profile/progress'
import { hasCharacter, loadProfile, saveProfile } from '../profile/store'
import { BOARD_CELL_PX, LINE_STROKE, type Settings } from '../settings/store'

interface LearnProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

const TRACKS: { id: TrackId; titleKey: 'learnBasics' | 'learnFuseki' | 'learnTsumego' }[] = [
  { id: 'basics', titleKey: 'learnBasics' },
  { id: 'fuseki', titleKey: 'learnFuseki' },
  { id: 'tsumego', titleKey: 'learnTsumego' },
]

type PlayEval = {
  ok: boolean
  next?: GameState
  msgKey: DictKey
  /** 정답 시 해설 병기 */
  withNote?: boolean
  reset?: boolean
}

function evaluatePlay(problem: LearnProblem, board: GameState, x: number, y: number): PlayEval {
  const isSol = problem.solutions.some((s) => s.x === x && s.y === y)
  if (!isSol) {
    return { ok: false, msgKey: 'learnWrongPoint' }
  }
  const r = tryPlay(board, x, y)
  if (!r.ok) {
    return { ok: false, msgKey: 'illegal' }
  }
  if (problem.goal === 'capture') {
    if (r.move.captured.length > 0) {
      return { ok: true, next: r.state, msgKey: 'learnCorrectCapture', withNote: true }
    }
    return { ok: false, msgKey: 'learnNoCapture', reset: true }
  }
  // place / kill / live — 정답 교차점 착수면 클리어
  return { ok: true, next: r.state, msgKey: 'learnCorrect', withNote: true }
}

function findStageSafe(id: string) {
  return STAGES.find((s) => s.id === id)
}

function initialLearnView(p: LearnProgress) {
  const track = p.lastTrack
  const trackStages = stagesForTrack(track)
  const stage =
    trackStages.find((s) => s.id === p.lastStageId && isStageUnlocked(s.id, p.solved)) ??
    trackStages.find((s) => isStageUnlocked(s.id, p.solved)) ??
    trackStages[0]
  const pIdx = Math.max(
    0,
    stage?.problems.findIndex((pr) => pr.id === p.lastProblemId) ?? 0,
  )
  const problem = stage?.problems[pIdx] ?? stage?.problems[0]
  return { track, stage, pIdx: problem ? stage!.problems.indexOf(problem) : 0, problem }
}

export function Learn({ lang, settings, onBack }: LearnProps) {
  const boot = useMemo(() => initialLearnView(loadLearnProgress()), [])
  const [progress, setProgress] = useState<LearnProgress>(() => loadLearnProgress())
  const [track, setTrack] = useState<TrackId>(boot.track)
  const trackStages = useMemo(() => stagesForTrack(track), [track])

  const [stageId, setStageId] = useState(boot.stage?.id ?? trackStages[0]?.id ?? '')
  const stage: LearnStage | undefined = findStageSafe(stageId) ?? trackStages[0]

  const [problemIdx, setProblemIdx] = useState(boot.pIdx)
  const problem = stage?.problems[problemIdx] ?? stage?.problems[0]

  const [board, setBoard] = useState<GameState>(() =>
    boot.problem ? problemState(boot.problem) : problemState(STAGES[0].problems[0]),
  )
  const [status, setStatus] = useState<'play' | 'ok' | 'miss'>('play')
  /** 힌트 단계: 0 없음 → 1 힌트 → 2 정답 */
  const [hintLevel, setHintLevel] = useState<0 | 1 | 2>(0)
  const [msg, setMsg] = useState(() =>
    boot.problem ? loc(lang, boot.problem.goalLabel) : '',
  )
  const [xpNote, setXpNote] = useState('')

  const markers: Array<Point & { label?: string }> = useMemo(() => {
    if (!problem) return []
    if (!(hintLevel === 2 || status === 'ok')) return []
    return problem.solutions.map((pt, i) => ({
      ...pt,
      label: i === 0 ? t(lang, 'answerLabel') : `${i + 1}`,
    }))
  }, [hintLevel, status, problem, lang])

  function selectTrack(id: TrackId) {
    setTrack(id)
    const stages = stagesForTrack(id)
    const unlocked = stages.find((s) => isStageUnlocked(s.id, progress.solved)) ?? stages[0]
    openStage(unlocked, 0)
    const next = { ...progress, lastTrack: id, lastStageId: unlocked.id }
    setProgress(next)
    saveLearnProgress(next)
  }

  function openStage(s: LearnStage, pIdx: number) {
    if (!isStageUnlocked(s.id, progress.solved)) return
    setStageId(s.id)
    const p = s.problems[Math.min(pIdx, s.problems.length - 1)]
    setProblemIdx(s.problems.indexOf(p))
    setBoard(problemState(p))
    setStatus('play')
    setHintLevel(0)
    setMsg(loc(lang, p.goalLabel))
    setXpNote('')
    const next = { ...progress, lastStageId: s.id, lastProblemId: p.id, lastTrack: s.track }
    setProgress(next)
    saveLearnProgress(next)
  }

  function loadProblem(s: LearnStage, index: number) {
    openStage(s, index)
  }

  /** 첫 클리어 시 프로필 XP 지급 (+스테이지 완주 보너스) */
  function awardXp(solvedProblemId: string, solvedNow: LearnProgress) {
    const profile = loadProfile()
    if (!hasCharacter(profile)) return
    const firstTime = !progress.solved.includes(solvedProblemId)
    if (!firstTime) return
    const stageDoneNow =
      stage != null &&
      isStageCleared(stage.id, solvedNow.solved) &&
      !isStageCleared(stage.id, progress.solved)
    const r = recordLearnSolve(profile, { stageCleared: stageDoneNow })
    saveProfile(r.profile)
    const parts = [`${t(lang, 'profileXpGain')} +${r.xpGained}`]
    if (r.leveledUp > 0) parts.push(`${t(lang, 'profileLevelUp')} → Lv.${r.profile.level}`)
    setXpNote(parts.join(' · '))
  }

  function onPuzzlePlay(x: number, y: number) {
    if (!problem || !stage || status === 'ok') return
    const result = evaluatePlay(problem, board, x, y)
    if (result.next && result.ok) {
      setBoard(result.next)
      playMoveSound(settings.moveSound)
    } else if (result.reset) {
      setBoard(problemState(problem))
    }
    const base = t(lang, result.msgKey)
    const note = result.withNote && problem.note ? ` ${loc(lang, problem.note)}` : ''
    setMsg(`${base}${note}`)
    if (result.ok) {
      setStatus('ok')
      const updated = markSolved(problem.id)
      awardXp(problem.id, updated)
      setProgress(updated)
    } else {
      setStatus('miss')
    }
  }

  const cleared = stage ? isStageCleared(stage.id, progress.solved) : false
  const counts = trackClearCount(track, progress.solved)
  const isLastProblem = stage ? problemIdx >= stage.problems.length - 1 : true

  return (
    <section className="screen learn">
      <header className="screen-head">
        <h2>{t(lang, 'learn')}</h2>
        <button type="button" className="btn" onClick={onBack}>
          {t(lang, 'back')}
        </button>
      </header>

      <p className="hint learn-refs" role="note">
        {t(lang, 'learnCurriculumNote')}
      </p>

      <div className="tab-row" role="tablist" aria-label={t(lang, 'learn')}>
        {TRACKS.map((tr) => {
          const c = trackClearCount(tr.id, progress.solved)
          return (
            <button
              key={tr.id}
              type="button"
              role="tab"
              aria-selected={track === tr.id}
              className={`tab-btn ${track === tr.id ? 'is-active' : ''}`}
              onClick={() => selectTrack(tr.id)}
            >
              {t(lang, tr.titleKey)}
              <span className="nav-btn-sub mono">
                {c.cleared}/{c.total}
              </span>
            </button>
          )
        })}
      </div>

      <div className="learn-layout">
        <aside className="learn-stages panel" aria-label={t(lang, 'learnStages')}>
          <p className="meta mono">
            {t(lang, 'learnTrackProgress')}: {counts.cleared}/{counts.total}
          </p>
          <ol className="stage-list">
            {trackStages.map((s) => {
              const unlocked = isStageUnlocked(s.id, progress.solved)
              const done = isStageCleared(s.id, progress.solved)
              return (
                <li key={s.id}>
                  <button
                    type="button"
                    className={`toc-btn ${s.id === stage?.id ? 'is-active' : ''}${done ? ' stage-cleared' : ''}`}
                    disabled={!unlocked}
                    aria-disabled={!unlocked}
                    onClick={() => openStage(s, 0)}
                  >
                    {done ? '✓ ' : unlocked ? '' : '🔒 '}
                    {loc(lang, s.title)}
                  </button>
                </li>
              )
            })}
          </ol>
        </aside>

        {stage && problem && (
          <div className="practice learn-main">
            <h3>{loc(lang, stage.title)}</h3>
            <p className="lesson-card learn-blurb">{loc(lang, stage.blurb)}</p>
            <p className="hint">{loc(lang, stage.refs)}</p>
            {cleared && (
              <p className="done-msg" role="status">
                {t(lang, 'learnStageCleared')}
              </p>
            )}

            <h4>
              {problemIdx + 1}/{stage.problems.length}. {loc(lang, problem.title)}
              {progress.solved.includes(problem.id) ? ' ✓' : ''}
            </h4>
            <p className={status === 'ok' ? 'done-msg' : status === 'miss' ? 'error' : 'meta'} role="status">
              {msg || loc(lang, problem.goalLabel)}
            </p>
            {xpNote && (
              <p className="done-msg" role="status">
                {xpNote}
              </p>
            )}

            <div className="game-layout">
              <Board
                lang={lang}
                state={board}
                interactive={status !== 'ok'}
                blink={settings.blinkIntersections}
                maxContrast={settings.maxContrastBoard}
                reduceMotion={settings.reduceMotion}
                lastMove={null}
                blackStone={settings.blackStone}
                whiteStone={settings.whiteStone}
                markers={markers}
                cellSize={BOARD_CELL_PX[settings.boardScale]}
                lineWidth={LINE_STROKE[settings.lineWeight]}
                onPlay={onPuzzlePlay}
                ariaLabel={loc(lang, problem.title)}
              />
              <aside className="panel">
                {hintLevel >= 1 ? (
                  <p>{loc(lang, problem.hint)}</p>
                ) : (
                  <p className="meta">{loc(lang, problem.goalLabel)}</p>
                )}
                <div className="btn-row">
                  {hintLevel === 0 && status !== 'ok' && (
                    <button type="button" className="btn" onClick={() => setHintLevel(1)}>
                      {t(lang, 'learnShowHint')}
                    </button>
                  )}
                  {hintLevel === 1 && status !== 'ok' && (
                    <button type="button" className="btn" onClick={() => setHintLevel(2)}>
                      {t(lang, 'learnShowAnswer')}
                    </button>
                  )}
                  <button type="button" className="btn" onClick={() => loadProblem(stage, problemIdx)}>
                    {t(lang, 'learnRetry')}
                  </button>
                </div>
                <div className="btn-row">
                  <button
                    type="button"
                    className="btn"
                    disabled={problemIdx <= 0}
                    onClick={() => loadProblem(stage, problemIdx - 1)}
                  >
                    {t(lang, 'prev')}
                  </button>
                  <button
                    type="button"
                    className={`btn${status === 'ok' && !isLastProblem ? ' btn-primary' : ''}`}
                    disabled={isLastProblem}
                    onClick={() => loadProblem(stage, problemIdx + 1)}
                  >
                    {t(lang, 'next')}
                  </button>
                </div>
                <ol className="puzzle-list">
                  {stage.problems.map((p, i) => (
                    <li key={p.id}>
                      <button
                        type="button"
                        className={`toc-btn ${i === problemIdx ? 'is-active' : ''}`}
                        onClick={() => loadProblem(stage, i)}
                      >
                        {progress.solved.includes(p.id) ? '✓ ' : ''}
                        {loc(lang, p.title)}
                      </button>
                    </li>
                  ))}
                </ol>
              </aside>
            </div>
          </div>
        )}
      </div>
    </section>
  )
}
