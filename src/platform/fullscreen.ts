/** Browser Fullscreen API + Tauri window fullscreen. */

function isTauri(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window
}

export async function enterFullscreen(): Promise<void> {
  try {
    if (isTauri()) {
      const { getCurrentWindow } = await import('@tauri-apps/api/window')
      await getCurrentWindow().setFullscreen(true)
      return
    }
  } catch {
    /* fall through to browser API */
  }
  try {
    if (!document.fullscreenElement) {
      await document.documentElement.requestFullscreen?.()
    }
  } catch {
    /* user gesture / permission — ignore */
  }
}

export async function exitFullscreen(): Promise<void> {
  try {
    if (isTauri()) {
      const { getCurrentWindow } = await import('@tauri-apps/api/window')
      await getCurrentWindow().setFullscreen(false)
      return
    }
  } catch {
    /* fall through */
  }
  try {
    if (document.fullscreenElement) {
      await document.exitFullscreen?.()
    }
  } catch {
    /* ignore */
  }
}
