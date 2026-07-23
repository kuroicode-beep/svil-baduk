/** Web Audio로 짧은 착수 클릭 — 외부 파일 없음 */

let ctx: AudioContext | null = null

function getCtx(): AudioContext | null {
  try {
    if (!ctx) ctx = new AudioContext()
    return ctx
  } catch {
    return null
  }
}

export function playMoveSound(enabled: boolean) {
  if (!enabled) return
  const ac = getCtx()
  if (!ac) return
  void ac.resume()
  const t0 = ac.currentTime
  const osc = ac.createOscillator()
  const gain = ac.createGain()
  osc.type = 'sine'
  osc.frequency.setValueAtTime(520, t0)
  osc.frequency.exponentialRampToValueAtTime(180, t0 + 0.08)
  gain.gain.setValueAtTime(0.0001, t0)
  gain.gain.exponentialRampToValueAtTime(0.22, t0 + 0.01)
  gain.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.12)
  osc.connect(gain)
  gain.connect(ac.destination)
  osc.start(t0)
  osc.stop(t0 + 0.14)
}
