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
  onPeer?: (peerId: string, meta: { name: string }) => void
  onMessage?: (msg: P2PMessage) => void
  onClose?: () => void
  onError?: (err: Error) => void
}

/**
 * PeerJS 공개 시그널링 — 앱 서버 없이 WebRTC DataChannel.
 * (시그널만 외부, 대국 데이터는 P2P)
 */
export class BadukP2P {
  private peer: Peer | null = null
  private conn: DataConnection | null = null
  private events: SessionEvents

  constructor(events: SessionEvents = {}) {
    this.events = events
  }

  start(preferredId?: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.peer = preferredId
        ? new Peer(preferredId, { debug: 0 })
        : new Peer({ debug: 0 })
      this.peer.on('open', (id) => {
        this.events.onReady?.(id)
        resolve(id)
      })
      this.peer.on('connection', (conn) => {
        this.attach(conn)
      })
      this.peer.on('error', (err) => {
        this.events.onError?.(err)
        reject(err)
      })
    })
  }

  connect(remoteId: string): Promise<void> {
    if (!this.peer) return Promise.reject(new Error('peer_not_ready'))
    return new Promise((resolve, reject) => {
      const conn = this.peer!.connect(remoteId, { reliable: true })
      conn.on('open', () => {
        this.attach(conn)
        resolve()
      })
      conn.on('error', reject)
    })
  }

  private attach(conn: DataConnection) {
    this.conn = conn
    conn.on('data', (data) => {
      this.events.onMessage?.(data as P2PMessage)
    })
    conn.on('close', () => this.events.onClose?.())
  }

  send(msg: P2PMessage) {
    this.conn?.send(msg)
  }

  destroy() {
    this.conn?.close()
    this.peer?.destroy()
    this.conn = null
    this.peer = null
  }
}
