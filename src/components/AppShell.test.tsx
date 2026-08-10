// src/components/AppShell.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { AppShell } from './AppShell'
import { APP_VERSION } from '../version'

function renderShell(overrides: Partial<Parameters<typeof AppShell>[0]> = {}) {
  const onNavigate = vi.fn()
  const utils = render(
    <AppShell lang="ko" screen="learn" onNavigate={onNavigate} {...overrides}>
      <p>본문</p>
    </AppShell>,
  )
  return { onNavigate, ...utils }
}

describe('AppShell', () => {
  it('배너·본문 랜드마크와 스킵 링크를 제공한다', () => {
    renderShell()
    expect(screen.getByRole('banner')).toBeInTheDocument()
    const main = screen.getByRole('main')
    expect(main).toHaveAttribute('id', 'main')
    const skip = screen.getByRole('link', { name: /본문으로/ })
    expect(skip).toHaveAttribute('href', '#main')
  })

  it('버전 배지를 전 화면에서 보여준다 — 예전엔 홈에만 있었다', () => {
    renderShell({ screen: 'solo' })
    expect(screen.getByText(`v${APP_VERSION}`)).toBeInTheDocument()
  })

  it('홈에서는 홈 버튼을, 설정에서는 설정 버튼을 숨긴다', () => {
    const { unmount } = renderShell({ screen: 'home' })
    expect(screen.queryByRole('button', { name: '홈' })).toBeNull()
    expect(screen.getByRole('button', { name: '설정' })).toBeInTheDocument()
    unmount()

    renderShell({ screen: 'settings' })
    expect(screen.getByRole('button', { name: '홈' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: '설정' })).toBeNull()
  })

  it('홈·설정 버튼이 이동을 요청한다', async () => {
    const user = userEvent.setup()
    const { onNavigate } = renderShell({ screen: 'profile' })
    await user.click(screen.getByRole('button', { name: '홈' }))
    expect(onNavigate).toHaveBeenCalledWith('home')
    await user.click(screen.getByRole('button', { name: '설정' }))
    expect(onNavigate).toHaveBeenCalledWith('settings')
  })

  it('대국 화면에서도 헤더가 남아 홈으로 나갈 수 있다', () => {
    renderShell({ screen: 'solo', immersive: true })
    expect(screen.getByRole('button', { name: '홈' })).toBeInTheDocument()
  })

  it('화면 제목을 role=status 로 알린다', () => {
    renderShell({ screen: 'multi' })
    const status = screen.getByRole('status')
    expect(status).toHaveTextContent('상대랑 두기')
    expect(status).toHaveAttribute('aria-live', 'polite')
  })

  it('화면이 바뀌면 본문으로 포커스를 옮긴다 (첫 렌더에서는 뺏지 않는다)', () => {
    const { rerender } = render(
      <AppShell lang="ko" screen="home" onNavigate={vi.fn()}>
        <p>본문</p>
      </AppShell>,
    )
    expect(document.activeElement).toBe(document.body)

    rerender(
      <AppShell lang="ko" screen="learn" onNavigate={vi.fn()}>
        <p>본문</p>
      </AppShell>,
    )
    expect(document.activeElement).toBe(screen.getByRole('main'))
  })
})
