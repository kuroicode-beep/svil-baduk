import { setKataGoTransport, type KataGoTransport } from './katago'

export const DEFAULT_BRIDGE_URL = 'http://127.0.0.1:17419'

export type BridgeHealth = {
  ok: boolean
  running: boolean
  platform?: { os: string; arch: string; node: string }
  defaults?: {
    exe: string
    model: string | null
    config: string | null
    hasExe?: boolean
    hasModel?: boolean
  }
}

export async function probeBridge(baseUrl = DEFAULT_BRIDGE_URL): Promise<BridgeHealth | null> {
  try {
    const res = await fetch(`${baseUrl.replace(/\/$/, '')}/health`, {
      signal: AbortSignal.timeout(1500),
    })
    if (!res.ok) return null
    return (await res.json()) as BridgeHealth
  } catch {
    return null
  }
}

export function createBridgeTransport(baseUrl = DEFAULT_BRIDGE_URL): KataGoTransport {
  const root = baseUrl.replace(/\/$/, '')
  let connected = false

  return {
    isConnected: () => connected,
    async send(line: string) {
      const res = await fetch(`${root}/gtp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ line }),
      })
      const data = (await res.json()) as { ok: boolean; response?: string; error?: string }
      if (!res.ok || !data.ok) throw new Error(data.error || 'gtp_failed')
      return data.response ?? ''
    },
  }
}

export async function connectBridge(
  baseUrl: string,
  paths?: { exe?: string; model?: string; config?: string },
): Promise<{ ok: true } | { ok: false; error: string }> {
  const root = baseUrl.replace(/\/$/, '')
  try {
    const health = await probeBridge(root)
    if (!health) return { ok: false, error: 'bridge_offline' }

    if (!health.running) {
      const res = await fetch(`${root}/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(paths ?? {}),
      })
      const data = (await res.json()) as { ok: boolean; error?: string }
      if (!res.ok || !data.ok) {
        return { ok: false, error: data.error || 'start_failed' }
      }
    }

    const transport = createBridgeTransport(root)
    await transport.send('name')
    setKataGoTransport({
      send: transport.send,
      isConnected: () => true,
    })
    return { ok: true }
  } catch (e) {
    setKataGoTransport(null)
    return { ok: false, error: e instanceof Error ? e.message : String(e) }
  }
}

export function disconnectBridge() {
  setKataGoTransport(null)
}
