import { useEffect, useRef, useState } from 'react'
import { playMoveSound } from '../audio/moveSound'
import { Board } from '../components/Board'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { GamePanel } from '../components/GamePanel'
import { MoveAnnouncer } from '../components/MoveAnnouncer'
import { RoomQr } from '../components/RoomQr'
import { createGame, pass, resign, tryPlay } from '../engine/board'
import { estimateScore } from '../engine/scoring'
import type { BoardSize, Move, Point } from '../engine/types'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { applyP2PMessage, initialMultiState, type MultiState } from '../p2p/reducer'
import { BadukP2P, friendlyP2PError, type P2PMessage } from '../p2p/session'
import { enterFullscreen, exitFullscreen } from '../platform/fullscreen'
import { BOARD_CELL_PX, LINE_STROKE, resolveReduceMotion, type Settings } from '../settings/store'

interface MultiProps {
  lang: Lang
  settings: Settings
}

export function Multi({ lang, settings }: MultiProps) {
  const p2pRef = useRef<BadukP2P | null>(null)
  const langRef = useRef(lang)
  const phaseRef = useRef<'lobby' | 'play'>('lobby')
  const soundRef = useRef(settings.moveSound)
  const onMsgRef = useRef<(msg: P2PMessage) => void>(() => {})

  const [myId, setMyId] = useState('')
  const [peerInput, setPeerInput] = useState('')
  const [peerReady, setPeerReady] = useState(false)
  /** 프로토콜 상태는 한 덩어리 — 순수 리듀서가 갱신한다 */
  const [multi, setMulti] = useState<MultiState>(() => initialMultiState(9))
  const [error, setError] = useState('')
  const [confirmResign, setConfirmResign] = useState(false)

  const { phase, size, hostColor, myColor, connected, game: state } = multi
  /** 리듀서를 동기로 호출하기 위한 최신 상태 참조 */
  const multiRef = useRef(multi)
  multiRef.current = multi

  langRef.current = lang
  phaseRef.current = phase
  soundRef.current = settings.moveSound

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
    setMulti((m) => ({ ...m, connected: false, phase: 'lobby', game: createGame(m.size) }))
    if (message) setError(message)
  }

  function bootPeer() {
    p2pRef.current?.destroy()
    setMyId('')
    setPeerReady(false)
    setMulti((m) => ({ ...m, connected: false }))

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
          setMulti((m) => ({ ...m, connected: false }))
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
    // 리듀서를 동기로 돌려 부수효과를 정확히 한 번만 실행한다.
    // setMulti 업데이터 안에서 모으면 React 배칭·StrictMode 때문에 타이밍이 틀어진다.
    const prev = multiRef.current
    const { state, effects } = applyP2PMessage(prev, msg)
    multiRef.current = state // 같은 틱에 메시지가 연달아 와도 이어지게
    setMulti(state)

    for (const fx of effects) {
      if (fx.kind === 'send') p2pRef.current?.send(fx.msg)
      else if (fx.kind === 'sound') playMoveSound(soundRef.current)
    }
    // 핸드셰이크로 대국이 시작되면 이전 연결 오류 문구를 지운다
    if (prev.phase !== 'play' && state.phase === 'play') setError('')
  }

  function createRoom() {
    setMulti((m) => ({ ...m, amHost: true, myColor: m.hostColor, game: createGame(m.size) }))
    setError('')
  }

  async function joinRoom() {
    setMulti((m) => ({ ...m, amHost: false }))
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
      setMulti((m) => ({ ...m, connected: false, phase: 'lobby' }))
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
  const lastWasOpponent =
    !!state.history.length && state.history[state.history.length - 1].player !== myColor
  const blinkLastMove = humanTurn && lastWasOpponent && !!lastMove

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
    setMulti((m) => ({ ...m, game: r.state }))
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
      <section className="screen multi-lobby">
        <p className="hint">{t(lang, 'p2pHint')}</p>
        {error && <p className="error" role="alert">{error}</p>}
        <div className="setup-grid">
          <div className="setup-side">
            <div className="setup-panel field">
              <span className="field-label">{t(lang, 'yourId')}</span>
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
              {myId && <RoomQr value={myId} label="방 ID QR — 상대가 스캔하거나 ID를 입력" />}
            </div>
            <div className="setup-panel field">
              <span className="field-label">{t(lang, 'peerId')}</span>
              <input
                value={peerInput}
                onChange={(e) => setPeerInput(e.target.value)}
                className="mono"
                autoComplete="off"
              />
              <div className="btn-row">
                <button type="button" className="btn btn-primary" onClick={joinRoom} disabled={!peerReady}>
                  {t(lang, 'joinRoom')}
                </button>
                <button type="button" className="btn" onClick={bootPeer}>
                  {t(lang, 'reinitPeer')}
                </button>
              </div>
            </div>
          </div>
          <div className="setup-side">
            <fieldset className="field setup-panel">
              <legend>{t(lang, 'boardSize')}</legend>
              <div className="size-pick" role="group" aria-label={t(lang, 'boardSize')}>
                {([9, 13, 19] as BoardSize[]).map((n) => (
                  <button
                    key={n}
                    type="button"
                    className={`btn size-pick-btn${size === n ? ' size-pick-on' : ''}`}
                    aria-pressed={size === n}
                    onClick={() => setMulti((m) => ({ ...m, size: n, game: createGame(n) }))}
                  >
                    <span className="mono">{n}×{n}</span>
                  </button>
                ))}
              </div>
            </fieldset>
            <fieldset className="field setup-panel">
              <legend>{t(lang, 'playAs')} ({t(lang, 'hostLabel')})</legend>
              <div className="color-pick" role="group">
                <button
                  type="button"
                  className={`btn color-pick-btn${hostColor === 1 ? ' color-pick-on' : ''}`}
                  aria-pressed={hostColor === 1}
                  onClick={() => setMulti((m) => ({ ...m, hostColor: 1, myColor: 1 }))}
                >
                  {t(lang, 'black')}
                </button>
                <button
                  type="button"
                  className={`btn color-pick-btn${hostColor === 2 ? ' color-pick-on' : ''}`}
                  aria-pressed={hostColor === 2}
                  onClick={() => setMulti((m) => ({ ...m, hostColor: 2, myColor: 2 }))}
                >
                  {t(lang, 'white')}
                </button>
              </div>
            </fieldset>
            <div className="setup-panel lobby-status" role="status">
              <p className="status-line">{connected ? t(lang, 'connected') : t(lang, 'waiting')}</p>
              <button type="button" className="btn btn-primary" onClick={createRoom}>
                {t(lang, 'hostRoom')}
              </button>
            </div>
          </div>
        </div>
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
          reduceMotion={resolveReduceMotion(settings.reduceMotion)}
          lastMove={lastMove}
          blinkLastMove={blinkLastMove}
          blackStone={settings.blackStone}
          whiteStone={settings.whiteStone}
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
              setMulti((m) => ({ ...m, game: r.state }))
              sendMove(r.move)
            }
          }}
          onResign={() => setConfirmResign(true)}
          onBack={goLobbyFromGame}
        />
      </div>

      <ConfirmDialog
        open={confirmResign}
        lang={lang}
        tone="danger"
        title={t(lang, 'resignConfirmTitle')}
        body={t(lang, 'resignConfirmBody')}
        confirmLabel={t(lang, 'resign')}
        onCancel={() => setConfirmResign(false)}
        onConfirm={() => {
          setConfirmResign(false)
          p2pRef.current?.send({ type: 'resign', player: myColor })
          setMulti((m) => ({ ...m, game: resign(m.game, myColor) }))
        }}
      />
    </section>
  )
}
