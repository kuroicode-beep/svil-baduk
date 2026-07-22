import { useEffect, useRef, useState } from 'react'
import { Board } from '../components/Board'
import { GamePanel } from '../components/GamePanel'
import { createGame, pass, tryPlay } from '../engine/board'
import type { BoardSize, GameState, Move, Player, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { BadukP2P, type P2PMessage } from '../p2p/session'
import type { Settings } from '../settings/store'

interface MultiProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

export function Multi({ lang, settings, onBack }: MultiProps) {
  const p2pRef = useRef<BadukP2P | null>(null)
  const lobbyRef = useRef({ amHost: true, size: 9 as BoardSize, hostColor: 1 as Player })

  const [myId, setMyId] = useState('')
  const [peerInput, setPeerInput] = useState('')
  const [connected, setConnected] = useState(false)
  const [size, setSize] = useState<BoardSize>(9)
  const [hostColor, setHostColor] = useState<Player>(1)
  const [amHost, setAmHost] = useState(true)
  const [myColor, setMyColor] = useState<Player>(1)
  const [state, setState] = useState<GameState>(() => createGame(9))
  const [phase, setPhase] = useState<'lobby' | 'play'>('lobby')
  const [error, setError] = useState('')

  lobbyRef.current = { amHost, size, hostColor }

  useEffect(() => {
    const session = new BadukP2P({
      onReady: (id) => setMyId(id),
      onClose: () => {
        setConnected(false)
        setError('연결이 끊어졌습니다')
      },
      onError: (err) => setError(err.message),
      onMessage: (msg) => onPeerMessage(msg),
    })
    p2pRef.current = session
    session.start().catch((e: Error) => setError(e.message))
    return () => session.destroy()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  function onPeerMessage(msg: P2PMessage) {
    const lobby = lobbyRef.current

    if (msg.type === 'sync-request' && lobby.amHost) {
      p2pRef.current?.send({
        type: 'hello',
        name: 'host',
        size: lobby.size,
        hostColor: lobby.hostColor,
      })
      setMyColor(lobby.hostColor)
      setState(createGame(lobby.size))
      setConnected(true)
      setPhase('play')
      return
    }

    if (msg.type === 'hello') {
      setAmHost(false)
      setMyColor(msg.hostColor === 1 ? 2 : 1)
      setSize(msg.size)
      setState(createGame(msg.size))
      setConnected(true)
      setPhase('play')
      p2pRef.current?.send({ type: 'accept', name: 'guest' })
      return
    }

    if (msg.type === 'accept') {
      setConnected(true)
      setPhase('play')
      return
    }

    if (msg.type === 'move') {
      applyRemoteMove(msg.move)
      return
    }

    if (msg.type === 'resign') {
      setState((s) => ({ ...s, ended: true }))
    }
  }

  function applyRemoteMove(move: Move) {
    setState((s) => {
      if (move.pass) {
        const r = pass(s)
        return r.ok ? r.state : s
      }
      const r = tryPlay(s, move.x, move.y)
      return r.ok ? r.state : s
    })
  }

  function createRoom() {
    setAmHost(true)
    setMyColor(hostColor)
    setState(createGame(size))
    setError('')
  }

  async function joinRoom() {
    setAmHost(false)
    setError('')
    try {
      await p2pRef.current?.connect(peerInput.trim())
      p2pRef.current?.send({ type: 'sync-request' })
    } catch (e) {
      setError(e instanceof Error ? e.message : 'join failed')
    }
  }

  const humanTurn = phase === 'play' && !state.ended && state.toPlay === myColor

  const lastMove: Point | null =
    state.history.length && !state.history[state.history.length - 1].pass
      ? {
          x: state.history[state.history.length - 1].x,
          y: state.history[state.history.length - 1].y,
        }
      : null

  function sendMove(move: Move) {
    p2pRef.current?.send({ type: 'move', move })
  }

  function onPlay(x: number, y: number) {
    if (!humanTurn) return
    const r = tryPlay(state, x, y)
    if (!r.ok) {
      setError(t(lang, 'illegal'))
      return
    }
    setError('')
    setState(r.state)
    sendMove(r.move)
  }

  if (phase === 'lobby') {
    return (
      <section className="screen">
        <header className="screen-head">
          <h2>{t(lang, 'multi')}</h2>
          <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
        </header>
        <p className="hint">서버리스 WebRTC P2P (PeerJS 시그널링)</p>
        {error && <p className="error" role="alert">{error}</p>}
        <label className="field">
          <span>{t(lang, 'yourId')}</span>
          <div className="id-row">
            <code className="mono id-box">{myId || '…'}</code>
            <button
              type="button"
              className="btn"
              disabled={!myId}
              onClick={() => navigator.clipboard.writeText(myId)}
            >
              {t(lang, 'copyId')}
            </button>
          </div>
        </label>
        <label className="field">
          <span>{t(lang, 'boardSize')}</span>
          <select value={size} onChange={(e) => setSize(Number(e.target.value) as BoardSize)}>
            <option value={9}>9×9</option>
            <option value={13}>13×13</option>
            <option value={19}>19×19</option>
          </select>
        </label>
        <fieldset className="field">
          <legend>{t(lang, 'playAs')} (호스트)</legend>
          <label className="radio">
            <input type="radio" checked={hostColor === 1} onChange={() => setHostColor(1)} />
            {t(lang, 'black')}
          </label>
          <label className="radio">
            <input type="radio" checked={hostColor === 2} onChange={() => setHostColor(2)} />
            {t(lang, 'white')}
          </label>
        </fieldset>
        <button type="button" className="btn btn-primary" onClick={createRoom}>
          {t(lang, 'hostRoom')}
        </button>
        <label className="field">
          <span>{t(lang, 'peerId')}</span>
          <input
            value={peerInput}
            onChange={(e) => setPeerInput(e.target.value)}
            className="mono"
            autoComplete="off"
          />
        </label>
        <button type="button" className="btn btn-primary" onClick={joinRoom}>
          {t(lang, 'joinRoom')}
        </button>
        <p className="meta">{connected ? t(lang, 'connected') : t(lang, 'waiting')}</p>
      </section>
    )
  }

  return (
    <section className="screen game-screen">
      <p className="sr-help">{t(lang, 'blinkHelp')}</p>
      {error && <p className="error" role="alert">{error}</p>}
      <div className="game-layout">
        <Board
          state={state}
          interactive={humanTurn}
          blink={settings.blinkIntersections}
          maxContrast={settings.maxContrastBoard}
          reduceMotion={settings.reduceMotion}
          lastMove={lastMove}
          onPlay={onPlay}
          ariaLabel={t(lang, 'multi')}
        />
        <GamePanel
          lang={lang}
          state={state}
          statusText={
            state.ended
              ? t(lang, 'gameOver')
              : humanTurn
                ? t(lang, 'yourTurn')
                : t(lang, 'waiting')
          }
          onPass={() => {
            if (!humanTurn) return
            const r = pass(state)
            if (r.ok) {
              setState(r.state)
              sendMove(r.move)
            }
          }}
          onResign={() => {
            p2pRef.current?.send({ type: 'resign', player: myColor })
            setState({ ...state, ended: true })
          }}
          onBack={() => {
            p2pRef.current?.destroy()
            onBack()
          }}
        />
      </div>
    </section>
  )
}
