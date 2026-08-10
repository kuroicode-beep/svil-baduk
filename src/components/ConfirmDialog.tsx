// src/components/ConfirmDialog.tsx — 되돌릴 수 없는 동작 확인창
//
// 네이티브 <dialog> + showModal() 을 쓴다. 포커스 트랩·Esc 닫기·배경 inert·
// aria-modal 의미가 전부 플랫폼에서 나오므로 의존성도 포커스 트랩 코드도 없다.
//
// 0.8.x 까지 앱에는 확인창 패턴이 아예 없었고, 그래서 기권 버튼은 한 번 누르면
// 즉시 대국이 끝났다.

import { useEffect, useRef } from 'react'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface ConfirmDialogProps {
  open: boolean
  lang: Lang
  title: string
  /** 본문 — 좌표 등을 넣어 구체적으로 쓴다 */
  body: string
  confirmLabel?: string
  cancelLabel?: string
  /** danger 는 기본 포커스를 '취소'에 둔다 */
  tone?: 'normal' | 'danger'
  onConfirm: () => void
  onCancel: () => void
}

export function ConfirmDialog({
  open,
  lang,
  title,
  body,
  confirmLabel,
  cancelLabel,
  tone = 'normal',
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const ref = useRef<HTMLDialogElement>(null)
  const cancelRef = useRef<HTMLButtonElement>(null)
  const confirmRef = useRef<HTMLButtonElement>(null)
  /** 열기 직전에 포커스가 있던 곳 — 닫을 때 되돌려준다 */
  const returnTo = useRef<HTMLElement | null>(null)

  useEffect(() => {
    const dlg = ref.current
    if (!dlg) return
    if (open && !dlg.open) {
      returnTo.current = document.activeElement as HTMLElement | null
      dlg.showModal()
      // 파괴적 동작은 취소에 포커스를 둬서 엔터 연타로 실행되지 않게 한다
      const target = tone === 'danger' ? cancelRef.current : confirmRef.current
      target?.focus()
    } else if (!open && dlg.open) {
      dlg.close()
      // 포커스 복귀는 여기서 직접 한다.
      // 'close' 이벤트 리스너에 맡기면, React 가 effect 정리를 먼저 돌려
      // 리스너를 떼어낸 뒤 close() 가 실행되므로 핸들러가 불리지 않는다.
      returnTo.current?.focus?.()
      returnTo.current = null
    }
  }, [open, tone])

  return (
    <dialog
      ref={ref}
      className={`confirm-dialog${tone === 'danger' ? ' confirm-dialog--danger' : ''}`}
      aria-labelledby="confirm-title"
      aria-describedby="confirm-body"
      /* 배경 클릭으로 닫지 않는다 — 저시력·터치에서 오조작이 잦다 */
      onCancel={(e) => {
        e.preventDefault()
        onCancel()
      }}
    >
      <h2 id="confirm-title" className="confirm-title">
        {title}
      </h2>
      <p id="confirm-body" className="confirm-body">
        {body}
      </p>
      <div className="confirm-actions">
        <button type="button" className="btn" ref={cancelRef} onClick={onCancel}>
          {cancelLabel ?? t(lang, 'cancel')}
        </button>
        <button
          type="button"
          className={`btn ${tone === 'danger' ? 'btn-danger' : 'btn-primary'}`}
          ref={confirmRef}
          onClick={onConfirm}
        >
          {confirmLabel ?? t(lang, 'confirm')}
        </button>
      </div>
    </dialog>
  )
}
