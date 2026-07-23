import { pointLabel } from '../engine/board'
import type { GameState } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface MoveAnnouncerProps {
  lang: Lang
  state: GameState
}

/** 스크린리더용 직전 수 낭독 */
export function MoveAnnouncer({ lang, state }: MoveAnnouncerProps) {
  const last = state.history[state.history.length - 1]
  if (!last) {
    return (
      <p className="sr-only" aria-live="polite" aria-atomic="true">
        {t(lang, 'yourTurn')}
      </p>
    )
  }
  const color = last.player === 1 ? t(lang, 'black') : t(lang, 'white')
  const where = last.pass ? t(lang, 'pass') : pointLabel(last.x, last.y)
  const cap =
    last.captured.length > 0
      ? ` · ${t(lang, 'captures')} ${last.captured.length}`
      : ''
  return (
    <p className="sr-only" aria-live="polite" aria-atomic="true">
      {color} {where}
      {cap}
    </p>
  )
}
