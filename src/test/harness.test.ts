// src/test/harness.test.ts — jsdom 셋업이 실제로 채워졌는지 확인
import { describe, expect, it } from 'vitest'

describe('jsdom harness', () => {
  it('provides matchMedia', () => {
    expect(typeof window.matchMedia).toBe('function')
    expect(window.matchMedia('(prefers-reduced-motion: reduce)').matches).toBe(false)
  })

  it('provides ResizeObserver', () => {
    expect(() => new ResizeObserver(() => {})).not.toThrow()
  })

  it('provides <dialog> showModal/close — jsdom does not implement these', () => {
    const dlg = document.createElement('dialog')
    document.body.appendChild(dlg)
    expect(dlg.open).toBe(false)
    dlg.showModal()
    expect(dlg.open).toBe(true)

    let closed = false
    dlg.addEventListener('close', () => {
      closed = true
    })
    dlg.close()
    expect(dlg.open).toBe(false)
    expect(closed).toBe(true)
    dlg.remove()
  })

  it('isolates localStorage between tests', () => {
    expect(localStorage.getItem('leak')).toBeNull()
    localStorage.setItem('leak', '1')
  })

  it('really isolates localStorage between tests', () => {
    expect(localStorage.getItem('leak')).toBeNull()
  })
})
