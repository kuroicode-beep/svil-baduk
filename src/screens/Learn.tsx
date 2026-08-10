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
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { BOARD_CELL_PX, LINE_STROKE, resolveReduceMotion, type Settings } from '../settings/store'

interface LearnProps {
  lang: Lang
  settings: Settings
}

const TRACKS: { id: TrackId; titleKey: 'learnBasics' | 'learnFuseki' | 'learnTsumego' }[] = [
  { id: 'basics', titleKey: 'learnBasics' },
  { id: 'fuseki', titleKey: 'learnFuseki' },
  { id: 'tsumego', titleKey: 'learnTsumego' },
]

function evaluatePlay(
  problem: LearnProblem,
  board: GameState,
  x: number,
  y: number,
): { ok: boolean; next?: GameState; msgKo: string; msgEn: string } {
  const isSol = problem.solutions.some((s) => s.x === x && s.y === y)
  if (!isSol) {
    return { ok: false, msgKo: '다른 자리입니다. 힌트를 보거나 다시 시도하세요.', msgEn: 'Wrong point. Try a hint or retry.' }
  }
  const r = tryPlay(board, x, y)
  if (!r.ok) {
    return { ok: false, msgKo: '둘 수 없는 자리입니다.', msgEn: 'Illegal move.' }
  }
  if (problem.goal === 'capture') {
    if (r.move.captured.length > 0) {
      return { ok: true, next: r.state, msgKo: '정답 — 따냈습니다!', msgEn: 'Correct — captured!' }
    }
    return {
      ok: false,
      next: board,
      msgKo: '착수는 맞았지만 따냄이 없습니다. 다시 시도하세요.',
      msgEn: 'Right point but no capture. Retry.',
    }
  }
  // place / kill / live — 정답 교차점 착수면 클리어
  return {
    ok: true,
    next: r.state,
    msgKo: problem.note?.ko ? `정답! ${problem.note.ko}` : '정답입니다!',
    msgEn: problem.note?.en ? `Correct! ${problem.note.en}` : 'Correct!',
  }
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

export function Learn({ lang, settings }: LearnProps) {
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
  const [showHint, setShowHint] = useState(false)
  const [msg, setMsg] = useState(() =>
    boot.problem ? loc(lang, boot.problem.goalLabel) : '',
  )

  const markers: Array<Point & { label?: string }> = useMemo(() => {
    if (!problem) return []
    if (!(showHint || status === 'ok')) return []
    return problem.solutions.map((pt, i) => ({ ...pt, label: i === 0 ? '정답' : `${i + 1}` }))
  }, [showHint, status, problem])

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
    setShowHint(false)
    setMsg(loc(lang, p.goalLabel))
    const next = { ...progress, lastStageId: s.id, lastProblemId: p.id, lastTrack: s.track }
    setProgress(next)
    saveLearnProgress(next)
  }

  function loadProblem(s: LearnStage, index: number) {
    openStage(s, index)
  }

  function onPuzzlePlay(x: number, y: number) {
    if (!problem || !stage || status === 'ok') return
    const result = evaluatePlay(problem, board, x, y)
    if (result.next && result.ok) {
      setBoard(result.next)
      playMoveSound(settings.moveSound)
    } else if (problem.goal === 'capture' && !result.ok && result.msgKo.includes('따냄이 없습니다')) {
      setBoard(problemState(problem))
    }
    setMsg(lang === 'ko' ? result.msgKo : result.msgEn)
    if (result.ok) {
      setStatus('ok')
      const updated = markSolved(problem.id)
      setProgress(updated)
    } else {
      setStatus('miss')
    }
  }

  const cleared = stage ? isStageCleared(stage.id, progress.solved) : false
  const counts = trackClearCount(track, progress.solved)

  return (
    <section className="screen learn">
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

            <div className="game-layout">
              <Board
                state={board}
                interactive={status !== 'ok'}
                blink={settings.blinkIntersections}
                reduceMotion={resolveReduceMotion(settings.reduceMotion)}
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
                <p>{loc(lang, problem.hint)}</p>
                <div className="btn-row">
                  <button type="button" className="btn" onClick={() => setShowHint(true)}>
                    {t(lang, 'learnShowAnswer')}
                  </button>
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
                    className="btn btn-primary"
                    disabled={problemIdx >= stage.problems.length - 1}
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
