// lib/application/multi_controller.dart — P2P 대국 세션의 두뇌
//
// 전송(P2PTransport)과 순수 리듀서(protocol.dart)를 잇는다.
// 판 상태의 소유자는 GameController 하나다 — 리듀서에는 매번 현재 판으로
// 스냅샷을 만들어 넘기고, 결과를 GameController 에 되돌린다. 두 군데에
// 판을 두면 반드시 갈라진다.
//
// 원격 수의 낭독은 GameController.applyOpponent 가 만든 PlayOutcome 을
// 그대로 화면에 넘겨서 해결한다 — 솔로와 같은 문장, 같은 채널.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/engine/types.dart';
import '../domain/input/coord_input.dart';
import '../domain/p2p/protocol.dart';
import '../domain/p2p/transport.dart';
import 'game_controller.dart';

/// 세션 사건 — 화면이 i18n 키를 번역해 낭독한다
sealed class MultiSessionEvent {
  const MultiSessionEvent();
}

/// 대국이 시작됐다 (핸드셰이크 완료)
final class MultiStarted extends MultiSessionEvent {
  const MultiStarted();
}

/// 원격에서 비롯된 판 변화 — speech 가 이미 들어 있다
final class MultiRemoteOutcome extends MultiSessionEvent {
  const MultiRemoteOutcome(this.outcome);
  final PlayOutcome outcome;
}

/// 연결·프로토콜 문제. [reasonKey] 는 i18n 키.
final class MultiTrouble extends MultiSessionEvent {
  const MultiTrouble(this.reasonKey, {this.detail});
  final String reasonKey;
  final String? detail;
}

enum MultiScreenPhase { lobby, connecting, play }

class MultiController extends ChangeNotifier {
  MultiController({
    required P2PEndpoint endpoint,
    required GameController Function(BoardSize) makeGame,
    this.onSession,
  })  : _endpoint = endpoint,
        _makeGame = makeGame {
    game = _makeGame(size);
  }

  final P2PEndpoint _endpoint;
  final GameController Function(BoardSize) _makeGame;

  /// 세션 사건 통지 — 낭독은 화면 몫이다
  final void Function(MultiSessionEvent)? onSession;

  // ── 로비 상태 ────────────────────────────────────────────
  String myId = '';
  bool brokerReady = false;
  String errorKey = '';
  String? errorDetail;

  /// 호스트가 로비에서 고르는 값
  BoardSize size = BoardSize.s9;
  Player hostColor = Stone.black;

  // ── 세션 상태 ────────────────────────────────────────────
  MultiScreenPhase phase = MultiScreenPhase.lobby;
  bool amHost = true;
  Player myColor = Stone.black;
  bool connected = false;

  late GameController game;

  P2PTransport? _transport;
  StreamSubscription<TransportEvent>? _transportSub;
  StreamSubscription<P2PTransport>? _incomingSub;
  bool _disposed = false;

  bool get myTurn =>
      phase == MultiScreenPhase.play &&
      connected &&
      !game.state.ended &&
      game.state.toPlay == myColor;

  /// 브로커에 등록해 방을 연다. 실패해도 화면은 살아 있어야 한다.
  Future<void> openRoom() async {
    try {
      myId = await _endpoint.open();
      brokerReady = true;
      errorKey = '';
      _incomingSub = _endpoint.incoming.listen((P2PTransport t) {
        // 이미 대국 중이면 늦게 온 손님은 받지 않는다
        if (_transport != null) {
          unawaited(t.close());
          return;
        }
        _attach(t, asHost: true);
      });
    } on P2PException catch (e) {
      brokerReady = false;
      errorKey = e.reasonKey;
      errorDetail = e.detail;
    }
    if (!_disposed) notifyListeners();
  }

  /// 게스트 경로 — 상대 방으로 들어간다
  Future<void> join(String remoteId) async {
    if (phase != MultiScreenPhase.lobby) return;
    phase = MultiScreenPhase.connecting;
    errorKey = '';
    notifyListeners();
    try {
      final P2PTransport t = await _endpoint.connect(remoteId);
      _attach(t, asHost: false);
      // 매 접속마다 전체 상태를 요청한다 — 첫 접속이든 재접속이든
      // 호스트의 Hello + StateMsg 가 대국을 세운다.
      t.send(const StateRequest().encode());
    } on P2PException catch (e) {
      phase = MultiScreenPhase.lobby;
      errorKey = e.reasonKey;
      errorDetail = e.detail;
      onSession?.call(MultiTrouble(e.reasonKey, detail: e.detail));
      if (!_disposed) notifyListeners();
    }
  }

  void _attach(P2PTransport t, {required bool asHost}) {
    _transport = t;
    amHost = asHost;
    if (asHost) {
      myColor = hostColor;
    }
    connected = true;
    _transportSub = t.events.listen(_onTransportEvent);
    notifyListeners();
  }

  void _onTransportEvent(TransportEvent e) {
    switch (e) {
      case TransportConnected():
        break; // connect()/incoming 완료 시점에 이미 처리됨
      case TransportMessage(:final String text):
        _onWire(text);
      case TransportClosed(:final String reasonKey, :final String? detail):
        connected = false;
        _transport = null;
        // 대국 전에 끊겼으면 로비로 되돌린다 — "접속 중" 에 갇히면 안 된다
        if (phase == MultiScreenPhase.connecting) {
          phase = MultiScreenPhase.lobby;
        }
        onSession?.call(MultiTrouble(reasonKey, detail: detail));
        if (!_disposed) notifyListeners();
    }
  }

  /// 리듀서에 넘길 스냅샷 — 판·seq 는 GameController 에서 유도한다
  MultiState _snapshot() => MultiState(
        phase: phase == MultiScreenPhase.play ? MultiPhase.play : MultiPhase.lobby,
        amHost: amHost,
        size: size,
        hostColor: hostColor,
        myColor: myColor,
        connected: connected,
        game: game.state,
        seq: game.state.history.length,
      );

  void _onWire(String raw) {
    final P2PMessage? msg = P2PMessage.decode(raw);
    if (msg == null) return;

    final P2PResult r = applyP2PMessage(_snapshot(), msg);

    // 리듀서 결과를 GameController 로 되돌린다.
    // MoveMsg 는 applyOpponent/pass 로 다시 적용해 낭독 문장을 얻는다 —
    // 리듀서가 이미 검증했으므로 같은 엔진 함수라 결과는 동일하다.
    switch (msg) {
      case Hello():
        if (r.state.error == MultiError.protocolMismatch) {
          onSession?.call(const MultiTrouble('protocolMismatch'));
        } else {
          amHost = false;
          size = r.state.size;
          hostColor = r.state.hostColor;
          myColor = r.state.myColor;
          game.dispose();
          game = _makeGame(size);
          _enterPlay();
        }
      case Accept():
        _enterPlay();
      case StateMsg():
        if (r.state.game.size != game.state.size) {
          game.dispose();
          game = _makeGame(r.state.size);
        }
        size = r.state.size;
        hostColor = r.state.hostColor;
        myColor = r.state.myColor;
        game.adoptState(r.state.game);
        _enterPlay();
      case MoveMsg(:final int x, :final int y, :final bool isPass):
        if (r.state.error == MultiError.none) {
          final PlayOutcome o =
              isPass ? game.pass() : game.applyOpponent(x, y);
          onSession?.call(MultiRemoteOutcome(o));
        }
        // 오류(badSequence·outOfTurn)는 재동기화 효과가 알아서 처리한다 —
        // 화면에 알릴 필요 없이 곧 StateMsg 로 복원된다.
      case ResignMsg(:final Player player):
        final PlayOutcome o = game.resignGame(player);
        onSession?.call(MultiRemoteOutcome(o));
      case StateRequest():
        if (amHost && phase != MultiScreenPhase.play) _enterPlay();
    }

    for (final P2PEffect fx in r.effects) {
      switch (fx) {
        case SendEffect(:final P2PMessage message):
          _transport?.send(message.encode());
        case SoundEffect():
          break; // 소리 계층은 아직 없다
      }
    }
    if (!_disposed) notifyListeners();
  }

  void _enterPlay() {
    final bool wasLobby = phase != MultiScreenPhase.play;
    phase = MultiScreenPhase.play;
    connected = true;
    errorKey = '';
    if (wasLobby) onSession?.call(const MultiStarted());
  }

  // ── 내 쪽 입력 ───────────────────────────────────────────

  /// 성공한 내 수(마지막 history 항목)를 상대에게 보낸다
  void _sendLastMove() {
    final List<Move> h = game.state.history;
    if (h.isEmpty) return;
    final Move m = h.last;
    _transport?.send(MoveMsg(
      seq: h.length - 1,
      player: m.player,
      x: m.x,
      y: m.y,
      isPass: m.isPass,
    ).encode());
  }

  /// 판(Enter)·좌표칸에서 온 착수를 처리하고, 성공이면 전송한다.
  PlayOutcome placeAt(int x, int y) {
    final PlayOutcome o = game.place(x, y);
    if (o is PlayedMove || o is GameEnded) _sendLastMove();
    return o;
  }

  PlayOutcome placeAtCursor() => placeAt(game.cursor.x, game.cursor.y);

  PlayOutcome passTurn() {
    final PlayOutcome o = game.pass();
    if (o is PlayedMove || o is GameEnded) _sendLastMove();
    return o;
  }

  /// 내 기권 — 상대에게 알리고 내 판도 끝낸다
  PlayOutcome resignMine() {
    _transport?.send(ResignMsg(player: myColor).encode());
    return game.resignGame(myColor);
  }

  /// 좌표칸 한 줄. 착수·패스·기권은 전송까지 책임진다.
  /// 무르기·힌트는 함께 두기에서 성립하지 않는다 — [notAvailablePhrase].
  PlayOutcome submitInput(
    String raw, {
    String? lastSpoken,
    required String notYourTurnPhrase,
    required String notAvailablePhrase,
  }) {
    final CoordInput parsed = parseCoordInput(raw, game.state.size);
    switch (parsed) {
      case CoordPoint(:final int x, :final int y):
        if (!myTurn) return InputError(notYourTurnPhrase);
        game.setCursor(Point(x, y));
        return placeAt(x, y);
      case CoordCommand(:final BoardCommand command):
        switch (command) {
          case BoardCommand.pass:
            if (!myTurn) return InputError(notYourTurnPhrase);
            return passTurn();
          case BoardCommand.resign:
            // 확인창 경유(A15) — 화면이 다이얼로그를 띄운 뒤 resignMine()
            return const SpokeOnly('');
          case BoardCommand.undo || BoardCommand.hint:
            return InputError(notAvailablePhrase);
          case BoardCommand.summary ||
                BoardCommand.repeat ||
                BoardCommand.score ||
                BoardCommand.help:
            return game.submitInput(raw, lastSpoken: lastSpoken);
        }
      case CoordQuery() || CoordError():
        return game.submitInput(raw, lastSpoken: lastSpoken);
    }
  }

  /// 좌표칸 입력이 기권 명령인지 — 화면이 확인창을 띄우기 위해 쓴다
  bool isResignCommand(String raw) {
    final CoordInput parsed = parseCoordInput(raw, game.state.size);
    return parsed is CoordCommand && parsed.command == BoardCommand.resign;
  }

  /// 로비로 되돌아간다 (연결 종료 포함)
  Future<void> leaveGame() async {
    await _transportSub?.cancel();
    _transportSub = null;
    await _transport?.close();
    _transport = null;
    connected = false;
    phase = MultiScreenPhase.lobby;
    game.dispose();
    game = _makeGame(size);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_transportSub?.cancel());
    unawaited(_incomingSub?.cancel());
    unawaited(_transport?.close());
    unawaited(_endpoint.dispose());
    game.dispose();
    super.dispose();
  }
}
