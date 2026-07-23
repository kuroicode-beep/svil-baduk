import { useMemo, useState } from 'react'
import { playMoveSound } from '../audio/moveSound'
import { Board } from '../components/Board'
import { tryPlay } from '../engine/board'
import type { GameState, Point } from '../engine/types'
import { lessonsFor, puzzlesFor } from '../learn/localize'
import { puzzleState, type Puzzle } from '../learn/puzzles'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { BOARD_CELL_PX, LINE_STROKE, type Settings } from '../settings/store'

interface LearnProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

type Tab = 'lessons' | 'practice'

export function Learn({ lang, settings, onBack }: LearnProps) {
  const lessons = useMemo(() => lessonsFor(lang), [lang])
  const puzzles = useMemo(() => puzzlesFor(lang), [lang])
  const [tab, setTab] = useState<Tab>('lessons')
  const [lessonIdx, setLessonIdx] = useState(0)
  const [stepIdx, setStepIdx] = useState(0)
  const [puzzleIdx, setPuzzleIdx] = useState(0)
  const [board, setBoard] = useState<GameState>(() => puzzleState(puzzlesFor(lang)[0]))
  const [status, setStatus] = useState<'play' | 'ok' | 'miss'>('play')
  const [showHint, setShowHint] = useState(false)
  const [msg, setMsg] = useState('')

  const lesson = lessons[lessonIdx]
  const step = lesson.steps[stepIdx]
  const lastStep = stepIdx >= lesson.steps.length - 1
  const lastLesson = lessonIdx >= lessons.length - 1
  const puzzle = puzzles[puzzleIdx]

  const markers: Point[] = useMemo(
    () => (showHint || status === 'ok' ? puzzle.solutions : []),
    [showHint, status, puzzle],
  )

  function loadPuzzle(p: Puzzle, index: number) {
    setPuzzleIdx(index)
    setBoard(puzzleState(p))
    setStatus('play')
    setShowHint(false)
    setMsg(p.goalLabel)
  }

  function next() {
    if (!lastStep) {
      setStepIdx((s) => s + 1)
      return
    }
    if (!lastLesson) {
      setLessonIdx((l) => l + 1)
      setStepIdx(0)
    }
  }

  function prev() {
    if (stepIdx > 0) {
      setStepIdx((s) => s - 1)
      return
    }
    if (lessonIdx > 0) {
      const prevLesson = lessons[lessonIdx - 1]
      setLessonIdx((l) => l - 1)
      setStepIdx(prevLesson.steps.length - 1)
    }
  }

  function onPuzzlePlay(x: number, y: number) {
    if (status === 'ok') return
    const isSol = puzzle.solutions.some((s) => s.x === x && s.y === y)
    if (!isSol) {
      setStatus('miss')
      setMsg('다른 자리입니다. 힌트를 보거나 다시 시도하세요.')
      return
    }
    const r = tryPlay(board, x, y)
    if (!r.ok) {
      setMsg(t(lang, 'illegal'))
      return
    }
    setBoard(r.state)
    playMoveSound(settings.moveSound)
    if (r.move.captured.length > 0) {
      setStatus('ok')
      setMsg('정답 — 따냈습니다!')
    } else {
      setStatus('miss')
      setMsg('착수는 맞았지만 따냄이 없습니다. 다시 시도하세요.')
      setBoard(puzzleState(puzzle))
    }
  }

  return (
    <section className="screen learn">
      <header className="screen-head">
        <h2>{t(lang, 'learn')}</h2>
        <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
      </header>

      <div className="tab-row" role="tablist" aria-label={t(lang, 'learn')}>
        <button
          type="button"
          role="tab"
          aria-selected={tab === 'lessons'}
          className={`tab-btn ${tab === 'lessons' ? 'is-active' : ''}`}
          onClick={() => setTab('lessons')}
        >
          {{ ko: '설명 레슨', en: 'Lessons', ja: '解説レッスン', zh: '讲解课程', vi: 'Bài học' }[lang]}
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === 'practice'}
          className={`tab-btn ${tab === 'practice' ? 'is-active' : ''}`}
          onClick={() => {
            setTab('practice')
            loadPuzzle(puzzles[puzzleIdx], puzzleIdx)
          }}
        >
          {{ ko: '따냄 연습', en: 'Capture drills', ja: '取り練習', zh: '提子练习', vi: 'Luyện bắt quân' }[lang]}
        </button>
      </div>

      {tab === 'lessons' && (
        <>
          <p className="lesson-progress mono">
            {lessonIdx + 1}/{lessons.length} · {stepIdx + 1}/{lesson.steps.length}
          </p>
          <h3>{lesson.title}</h3>
          <article className="lesson-card">
            <h4>{step.title}</h4>
            <p>{step.body}</p>
            {step.boardHint && (
              <p className="hint-badge" role="note">
                <span className="label">힌트</span> {step.boardHint}
              </p>
            )}
          </article>
          <div className="btn-row">
            <button type="button" className="btn" onClick={prev} disabled={lessonIdx === 0 && stepIdx === 0}>
              {t(lang, 'prev')}
            </button>
            {lastLesson && lastStep ? (
              <p className="done-msg">{t(lang, 'lessonDone')}</p>
            ) : (
              <button type="button" className="btn btn-primary" onClick={next}>
                {t(lang, 'next')}
              </button>
            )}
            <button type="button" className="btn" onClick={() => setTab('practice')}>
              {{ ko: '따냄 연습으로', en: 'Go to drills', ja: '取り練習へ', zh: '去做提子练习', vi: 'Sang luyện bắt' }[lang]}
            </button>
          </div>
          <ul className="lesson-toc">
            {lessons.map((l, i) => (
              <li key={l.id}>
                <button
                  type="button"
                  className={`toc-btn ${i === lessonIdx ? 'is-active' : ''}`}
                  onClick={() => {
                    setLessonIdx(i)
                    setStepIdx(0)
                  }}
                >
                  {l.title}
                </button>
              </li>
            ))}
          </ul>
        </>
      )}

      {tab === 'practice' && (
        <div className="practice">
          <h3>{puzzle.title}</h3>
          <p className={status === 'ok' ? 'done-msg' : status === 'miss' ? 'error' : 'meta'} role="status">
            {msg || puzzle.goalLabel}
          </p>
          <div className="game-layout">
            <Board
              state={board}
              interactive={status !== 'ok'}
              blink={settings.blinkIntersections}
              maxContrast={settings.maxContrastBoard}
              reduceMotion={settings.reduceMotion}
              lastMove={null}
              markers={markers}
              cellSize={BOARD_CELL_PX[settings.boardScale]}
              lineWidth={LINE_STROKE[settings.lineWeight]}
              onPlay={onPuzzlePlay}
              ariaLabel={puzzle.title}
            />
            <aside className="panel">
              <p>{puzzle.hint}</p>
              <div className="btn-row">
                <button type="button" className="btn" onClick={() => setShowHint(true)}>
                  정답 위치 보기
                </button>
                <button type="button" className="btn" onClick={() => loadPuzzle(puzzle, puzzleIdx)}>
                  다시 풀기
                </button>
              </div>
              <div className="btn-row">
                <button
                  type="button"
                  className="btn"
                  disabled={puzzleIdx <= 0}
                  onClick={() => loadPuzzle(puzzles[puzzleIdx - 1], puzzleIdx - 1)}
                >
                  {t(lang, 'prev')}
                </button>
                <button
                  type="button"
                  className="btn btn-primary"
                  disabled={puzzleIdx >= puzzles.length - 1}
                  onClick={() => loadPuzzle(puzzles[puzzleIdx + 1], puzzleIdx + 1)}
                >
                  {t(lang, 'next')}
                </button>
              </div>
              <ol className="puzzle-list">
                {puzzles.map((p, i) => (
                  <li key={p.id}>
                    <button
                      type="button"
                      className={`toc-btn ${i === puzzleIdx ? 'is-active' : ''}`}
                      onClick={() => loadPuzzle(p, i)}
                    >
                      {p.title}
                    </button>
                  </li>
                ))}
              </ol>
            </aside>
          </div>
        </div>
      )}
    </section>
  )
}
