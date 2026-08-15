/** Browser Fullscreen API.
 *  Tauri 분기는 0.20.0 에서 제거 — 데스크톱은 Flutter(app/)가 맡고
 *  이 코드는 웹 타깃 전용이다 (체크리스트 B10). */

export async function enterFullscreen(): Promise<void> {
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
    if (document.fullscreenElement) {
      await document.exitFullscreen?.()
    }
  } catch {
    /* ignore */
  }
}
