// src/components/ConfirmDialog.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { ConfirmDialog } from './ConfirmDialog'

function setup(props: Partial<Parameters<typeof ConfirmDialog>[0]> = {}) {
  const onConfirm = vi.fn()
  const onCancel = vi.fn()
  const utils = render(
    <ConfirmDialog
      open
      lang="ko"
      title="기권하시겠습니까?"
      body="되돌릴 수 없습니다."
      onConfirm={onConfirm}
      onCancel={onCancel}
      {...props}
    />,
  )
  return { onConfirm, onCancel, ...utils }
}

describe('ConfirmDialog', () => {
  it('열려 있을 때 제목·본문이 접근 가능한 이름으로 연결된다', () => {
    setup()
    const dlg = document.querySelector('dialog')!
    expect(dlg.open).toBe(true)
    expect(dlg).toHaveAttribute('aria-labelledby', 'confirm-title')
    expect(dlg).toHaveAttribute('aria-describedby', 'confirm-body')
    expect(screen.getByText('기권하시겠습니까?')).toBeInTheDocument()
    expect(screen.getByText('되돌릴 수 없습니다.')).toBeInTheDocument()
  })

  it('닫힌 상태로는 열리지 않는다', () => {
    setup({ open: false })
    expect(document.querySelector('dialog')!.open).toBe(false)
  })

  it('파괴적 동작은 취소에 기본 포커스를 둔다 — 엔터 연타 방지', () => {
    setup({ tone: 'danger' })
    expect(document.activeElement).toBe(screen.getByRole('button', { name: '취소' }))
  })

  it('보통 동작은 확인에 포커스를 둔다', () => {
    setup({ tone: 'normal' })
    expect(document.activeElement).toBe(screen.getByRole('button', { name: '확인' }))
  })

  it('확인·취소 버튼이 각각의 콜백을 부른다', async () => {
    const user = userEvent.setup()
    const { onConfirm, onCancel } = setup({ tone: 'danger', confirmLabel: '기권' })
    await user.click(screen.getByRole('button', { name: '기권' }))
    expect(onConfirm).toHaveBeenCalledTimes(1)
    await user.click(screen.getByRole('button', { name: '취소' }))
    expect(onCancel).toHaveBeenCalledTimes(1)
  })

  it('Esc 는 취소로 처리한다', () => {
    const { onCancel, onConfirm } = setup({ tone: 'danger' })
    const dlg = document.querySelector('dialog')!
    dlg.dispatchEvent(new Event('cancel', { cancelable: true, bubbles: true }))
    expect(onCancel).toHaveBeenCalled()
    expect(onConfirm).not.toHaveBeenCalled()
  })

  it('닫을 때 열기 전 포커스로 되돌린다', () => {
    const trigger = document.createElement('button')
    trigger.textContent = '기권'
    document.body.appendChild(trigger)
    trigger.focus()
    expect(document.activeElement).toBe(trigger)

    const { rerender } = render(
      <ConfirmDialog
        open
        lang="ko"
        title="제목"
        body="본문"
        onConfirm={vi.fn()}
        onCancel={vi.fn()}
      />,
    )
    rerender(
      <ConfirmDialog
        open={false}
        lang="ko"
        title="제목"
        body="본문"
        onConfirm={vi.fn()}
        onCancel={vi.fn()}
      />,
    )
    expect(document.activeElement).toBe(trigger)
    trigger.remove()
  })
})
