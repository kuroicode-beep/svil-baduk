import { useState } from 'react'
import { LESSONS } from '../learn/lessons'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface LearnProps {
  lang: Lang
  onBack: () => void
}

export function Learn({ lang, onBack }: LearnProps) {
  const [lessonIdx, setLessonIdx] = useState(0)
  const [stepIdx, setStepIdx] = useState(0)
  const lesson = LESSONS[lessonIdx]
  const step = lesson.steps[stepIdx]
  const lastStep = stepIdx >= lesson.steps.length - 1
  const lastLesson = lessonIdx >= LESSONS.length - 1

  function next() {
    if (!lastStep) {
      setStepIdx((s) => s + 1)
      return
    }
    if (!lastLesson) {
      setLessonIdx((l) => l + 1)
      setStepIdx(0)
      return
    }
  }

  function prev() {
    if (stepIdx > 0) {
      setStepIdx((s) => s - 1)
      return
    }
    if (lessonIdx > 0) {
      const prevLesson = LESSONS[lessonIdx - 1]
      setLessonIdx((l) => l - 1)
      setStepIdx(prevLesson.steps.length - 1)
    }
  }

  return (
    <section className="screen learn">
      <header className="screen-head">
        <h2>{t(lang, 'learn')}</h2>
        <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
      </header>
      <p className="lesson-progress mono">
        {lessonIdx + 1}/{LESSONS.length} · {stepIdx + 1}/{lesson.steps.length}
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
      </div>
      <ul className="lesson-toc">
        {LESSONS.map((l, i) => (
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
    </section>
  )
}
