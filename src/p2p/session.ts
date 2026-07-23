import Peer, { type DataConnection } from 'peerjs'
import type { BoardSize, Move, Player } from '../engine/types'

export type P2PMessage =
  | { type: 'hello'; name: string; size: BoardSize; hostColor: Player }
  | { type: 'accept'; name: string }
  | { type: 'move'; move: Move }
  | { type: 'resign'; player: Player }
  | { type: 'chat'; text: string }
  | { type: 'sync-request' }

export type SessionEvents = {
  onReady?: (myId: string) => void
  onMessage?: (msg: P2PMessage) => void
  onClose?: () => void
  onError?: (err: Error) => void
}

const CONNECT_TIMEOUT_MS = 15_000

/**
 * PeerJS 공개 시그널링 — 앱 서버 없이 WebRTC DataChannel.
 */
export class BadukP2P {
  private peer: Peer | null = null
  private conn: DataConnection | null = null
  private events: SessionEvents
  private opened = false

  constructor(events: SessionEvents = {}) {
    this.events = events
  }

  start(preferredId?: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.peer = preferredId
        ? new Peer(preferredId, { debug: 0 })
        : new Peer({ debug: 0 })

      this.peer.on('open', (id) => {
        this.opened = true
        this.events.onReady?.(id)
        resolve(id)
      })

      this.peer.on('connection', (conn) => {
        this.attach(conn)
      })

      this.peer.on('error', (err) => {
        const mapped = mapPeerError(err)
        this.events.onError?.(mapped)
        if (!this.opened) reject(mapped)
      })

      this.peer.on('disconnected', () => {
        // 시그널 서버와 끊김 — 자동 재시도
        try {
          this.peer?.reconnect()
        } catch {
          this.events.onError?.(new Error('signal_disconnected'))
        }
      })
    })
  }

  connect(remoteId: string): Promise<void> {
    if (!this.peer || !this.opened) {
      return Promise.reject(new Error('peer_not_ready'))
    }
    const id = remoteId.trim()
    if (!id) return Promise.reject(new Error('empty_peer_id'))

    return new Promise((resolve, reject) => {
      let settled = false
      const timer = window.setTimeout(() => {
        if (settled) return
        settled = true
        reject(new Error('connect_timeout'))
      }, CONNECT_TIMEOUT_MS)

      const conn = this.peer!.connect(id, { reliable: true })
      conn.on('open', () => {
        if (settled) return
        settled = true
        window.clearTimeout(timer)
        this.attach(conn)
        resolve()
      })
      conn.on('error', (err) => {
        if (settled) return
        settled = true
        window.clearTimeout(timer)
        reject(err instanceof Error ? err : new Error(String(err)))
      })
    })
  }

  private attach(conn: DataConnection) {
    if (this.conn && this.conn !== conn) {
      try {
        this.conn.close()
      } catch {
        /* ignore */
      }
    }
    this.conn = conn
    conn.on('data', (data) => {
      this.events.onMessage?.(data as P2PMessage)
    })
    conn.on('close', () => this.events.onClose?.())
    conn.on('error', (err) => {
      this.events.onError?.(err instanceof Error ? err : new Error(String(err)))
    })
  }

  send(msg: P2PMessage) {
    if (!this.conn?.open) {
      this.events.onError?.(new Error('not_connected'))
      return
    }
    this.conn.send(msg)
  }

  isConnected(): boolean {
    return !!this.conn?.open
  }

  destroy() {
    try {
      this.conn?.close()
    } catch {
      /* ignore */
    }
    try {
      this.peer?.destroy()
    } catch {
      /* ignore */
    }
    this.conn = null
    this.peer = null
    this.opened = false
  }
}

function mapPeerError(err: { type?: string; message?: string }): Error {
  const type = err.type || 'peer_error'
  if (type === 'peer-unavailable') return new Error('peer_unavailable')
  if (type === 'network') return new Error('network_error')
  if (type === 'server-error') return new Error('signal_error')
  if (type === 'browser-incompatible') return new Error('browser_incompatible')
  return new Error(type)
}

export function friendlyP2PError(code: string, fallback: string): string {
  switch (code) {
    case 'peer_unavailable':
    case 'connect_timeout':
    case 'network_error':
    case 'signal_error':
    case 'signal_disconnected':
    case 'not_connected':
    case 'empty_peer_id':
    case 'peer_not_ready':
    case 'browser_incompatible':
      return fallback
    default:
      return fallback
  }
}
