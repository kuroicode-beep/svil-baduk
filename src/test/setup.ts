// src/test/setup.ts — jsdom(ui) 프로젝트 전용 셋업
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach, beforeEach, vi } from 'vitest'

/**
 * jsdom에 없는 브라우저 API 채우기.
 * 앱이 실제로 의존하는 것만 넣는다 — 없으면 컴포넌트 테스트가
 "why is this undefined" 로 죽는다.
 */

// 1) matchMedia — reduceMotion:'system', prefers-contrast, pointer:coarse 판정에 쓰인다
if (!window.matchMedia) {
  window.matchMedia = ((query: string) => {
    const list = {
      matches: false,
      media: query,
      onchange: null,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    }
    return list as unknown as MediaQueryList
  }) as typeof window.matchMedia
}

// 2) ResizeObserver — 바둑판 좌표 자동 숨김이 실측 셀 크기를 본다
if (!globalThis.ResizeObserver) {
  globalThis.ResizeObserver = class {
    observe() {}
    unobserve() {}
    disconnect() {}
  } as unknown as typeof ResizeObserver
}

// 3) <dialog> — jsdom이 showModal/close를 구현하지 않는다. ConfirmDialog가 여기 걸린다.
if (typeof HTMLDialogElement !== 'undefined' && !HTMLDialogElement.prototype.showModal) {
  HTMLDialogElement.prototype.showModal = function showModal(this: HTMLDialogElement) {
    this.open = true
    this.setAttribute('open', '')
  }
  HTMLDialogElement.prototype.show = function show(this: HTMLDialogElement) {
    this.open = true
    this.setAttribute('open', '')
  }
  HTMLDialogElement.prototype.close = function close(this: HTMLDialogElement, returnValue?: string) {
    this.open = false
    this.removeAttribute('open')
    if (returnValue !== undefined) this.returnValue = returnValue
    this.dispatchEvent(new Event('close'))
  }
}

// 4) 전체화면 — Solo/Multi가 진입을 시도한다
if (!document.exitFullscreen) {
  document.exitFullscreen = () => Promise.resolve()
  Element.prototype.requestFullscreen = () => Promise.resolve()
}

// 5) AudioContext — 착수음
if (!globalThis.AudioContext) {
  globalThis.AudioContext = class {
    currentTime = 0
    destination = {}
    createOscillator() {
      return {
        type: '', frequency: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} },
        connect: () => {}, start: () => {}, stop: () => {},
      }
    }
    createGain() {
      return {
        gain: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} },
        connect: () => {},
      }
    }
    close() { return Promise.resolve() }
  } as unknown as typeof AudioContext
}

beforeEach(() => {
  localStorage.clear()
  vi.restoreAllMocks()
})

afterEach(() => {
  cleanup()
})
