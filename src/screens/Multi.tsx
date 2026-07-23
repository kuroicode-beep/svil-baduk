import { useEffect, useRef, useState } from 'react'
import { playMoveSound } from '../audio/moveSound'
import { Board } from '../components/Board'
import { GamePanel } from '../components/GamePanel'
import { MoveAnnouncer } from '../components/MoveAnnouncer'
import { RoomQr } from '../components/RoomQr'
import { createGame, pass, resign, tryPlay } from '../engine/board'
import { estimateScore } from '../engine/scoring'
import type { BoardSize, GameState, Move, Player, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { BadukP2P, friendlyP2PError, type P2PMessage } from '../p2p/session'
import { enterFullscreen, exitFullscreen } from '../platform/fullscreen'
import { BOARD_CELL_PX, LINE_STROKE, type Settings } from '../settings/store'

interface MultiProps {
  lang: Lang
  settings: Settings
  onBack: () => void
}

export function Multi({ lang, settings, onBack }: MultiProps) {
  const p2pRef = useRef<BadukP2P | null>(null)
  const lobbyRef = useRef({ amHost: true, size: 9 as BoardSize, hostColor: 1 as Player })
  const langRef = useRef(lang)
  const phaseRef = useRef<'lobby' | 'play'>('lobby')
  const soundRef = useRef(settings.moveSound)
  const onMsgRef = useRef<(msg: P2PMessage) => void>(() => {})

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
  const [peerReady, setPeerReady] = useState(false)

  langRef.current = lang
  phaseRef.current = phase
  soundRef.current = settings.moveSound
  lobbyRef.current = { amHost, size, hostColor }

  useEffect(() => {
    if (phase === 'play') {
      void enterFullscreen()
    } else {
      void exitFullscreen()
    }
    return () => {
      void exitFullscreen()
    }
  }, [phase])

  function returnToLobby(message?: string) {
    setConnected(false)
    setPhase('lobby')
    setState(createGame(lobbyRef.current.size))
    if (message) setError(message)
  }

  function bootPeer() {
    p2pRef.current?.destroy()
    setMyId('')
    setPeerReady(false)
    setConnected(false)

    const session = new BadukP2P({
      onReady: (id) => {
        setMyId(id)
        setPeerReady(true)
      },
      onClose: () => {
        returnToLobby(t(langRef.current, 'disconnected'))
      },
      onError: (err) => {
        setError(friendlyP2PError(err.message, t(langRef.current, 'connectFailed')))
        if (phaseRef.current === 'play') {
          setConnected(false)
        }
      },
      onMessage: (msg) => onMsgRef.current(msg),
    })
    p2pRef.current = session
    session.start().catch((e: Error) => {
      setError(friendlyP2PError(e.message, t(langRef.current, 'connectFailed')))
      setPeerReady(false)
    })
  }

  useEffect(() => {
    bootPeer()
    return () => p2pRef.current?.destroy()
    // mount once
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  onMsgRef.current = (msg: P2PMessage) => {
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
      setError('')
      setPhase('play')
      return
    }

    if (msg.type === 'hello') {
      setAmHost(false)
      setMyColor(msg.hostColor === 1 ? 2 : 1)
      setSize(msg.size)
      setState(createGame(msg.size))
      setConnected(true)
      setError('')
      setPhase('play')
      p2pRef.current?.send({ type: 'accept', name: 'guest' })
      return
    }

    if (msg.type === 'accept') {
      setConnected(true)
      setError('')
      setPhase('play')
      return
    }

    if (msg.type === 'move') {
      setState((s) => {
        if (msg.move.pass) {
          const r = pass(s)
          return r.ok ? r.state : s
        }
        const r = tryPlay(s, msg.move.x, msg.move.y)
        if (r.ok) playMoveSound(soundRef.current)
        return r.ok ? r.state : s
      })
      return
    }

    if (msg.type === 'resign') {
      setState((s) => resign(s, msg.player))
    }
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
    if (!peerReady) {
      setError(t(lang, 'connectFailed'))
      return
    }
    try {
      await p2pRef.current?.connect(peerInput.trim())
      p2pRef.current?.send({ type: 'sync-request' })
    } catch (e) {
      const code = e instanceof Error ? e.message : 'join failed'
      setError(friendlyP2PError(code, t(lang, 'connectFailed')))
      setConnected(false)
      setPhase('lobby')
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
      setError(r.reason === 'superko' || r.reason === 'ko' ? t(lang, 'superko') : t(lang, 'illegal'))
      return
    }
    setError('')
    setState(r.state)
    sendMove(r.move)
    playMoveSound(settings.moveSound)
  }

  function goLobbyFromGame() {
    try {
      p2pRef.current?.destroy()
    } catch {
      /* ignore */
    }
    returnToLobby()
    bootPeer()
  }

  if (phase === 'lobby') {
    return (
      <section className="screen">
        <header className="screen-head">
          <h2>{t(lang, 'multi')}</h2>
          <button type="button" className="btn" onClick={onBack}>{t(lang, 'back')}</button>
        </header>
        <p className="hint">{t(lang, 'p2pHint')}</p>
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
        {myId && <RoomQr value={myId} label="방 ID QR — 상대가 스캔하거나 ID를 입력" />}
        <label className="field">
          <span>{t(lang, 'boardSize')}</span>
          <select value={size} onChange={(e) => setSize(Number(e.target.value) as BoardSize)}>
            <option value={9}>9×9</option>
            <option value={13}>13×13</option>
            <option value={19}>19×19</option>
          </select>
        </label>
        <fieldset className="field">
          <legend>{t(lang, 'playAs')} ({t(lang, 'hostLabel')})</legend>
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
        <div className="btn-row">
          <button type="button" className="btn btn-primary" onClick={joinRoom} disabled={!peerReady}>
            {t(lang, 'joinRoom')}
          </button>
          <button type="button" className="btn" onClick={bootPeer}>
            {t(lang, 'reinitPeer')}
          </button>
        </div>
        <p className="meta">{connected ? t(lang, 'connected') : t(lang, 'waiting')}</p>
      </section>
    )
  }

  return (
    <section className="screen game-screen">
      <p className="sr-help">{t(lang, 'blinkHelp')}</p>
      <MoveAnnouncer lang={lang} state={state} />
      {error && (
        <div className="error-block">
          <p className="error" role="alert">{error}</p>
          <button type="button" className="btn" onClick={goLobbyFromGame}>
            {t(lang, 'returnLobby')}
          </button>
        </div>
      )}
      <div className="game-layout">
        <Board
          state={state}
          interactive={humanTurn}
          blink={settings.blinkIntersections}
          maxContrast={settings.maxContrastBoard}
          reduceMotion={settings.reduceMotion}
          lastMove={lastMove}
          ownership={state.ended ? estimateScore(state, settings.goRules).ownership : undefined}
          cellSize={BOARD_CELL_PX[settings.boardScale]}
          lineWidth={LINE_STROKE[settings.lineWeight]}
          onPlay={onPlay}
          ariaLabel={t(lang, 'multi')}
        />
        <GamePanel
          lang={lang}
          state={state}
          goRules={settings.goRules}
          statusText={
            state.ended
              ? `${t(lang, 'gameOver')} · ${t(lang, 'score')}`
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
            setState(resign(state, myColor))
          }}
          onBack={goLobbyFromGame}
        />
      </div>
    </section>
  )
}
