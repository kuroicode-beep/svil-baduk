// lib/domain/p2p/protocol.dart — P2P 메시지와 순수 리듀서
//
// React 판 src/p2p/reducer.ts 를 옮기되, 그때 문서로만 남겼던 결함들을 고친다.
//
// 프로토콜 2 에서 바뀐 것:
//  · state-request 가 실제로 전체 상태를 돌려준다.
//    (1 에서는 host 가 createGame 으로 **초기화**해버려서 재연결하면
//     늘 빈 판에서 다시 시작했다 — 대표 버그)
//  · 착수에 seq 를 붙이고 move.player 를 검증한다.
//    (1 은 수신자의 toPlay 로 적용해서 순서가 어긋나도 조용히 삼켰다)
//  · protocol 필드로 버전 불일치를 감지해 번역된 오류를 낸다 (행 대신)
//
// React 판(PeerJS/BinaryPack)과의 교차 대국은 지원하지 않는다.

import 'dart:convert';

import '../engine/board.dart';
import '../engine/types.dart';

const int kP2PProtocol = 2;

sealed class P2PMessage {
  const P2PMessage();
  Map<String, dynamic> toJson();

  static P2PMessage? fromJson(Map<String, dynamic> j) {
    switch (j['t']) {
      case 'hello':
        return Hello(
          name: j['name'] as String? ?? '',
          size: BoardSize.fromLines(j['size'] as int),
          hostColor: Stone.fromWire(j['hostColor'] as int),
          protocol: j['protocol'] as int? ?? 1,
        );
      case 'accept':
        return Accept(name: j['name'] as String? ?? '');
      case 'move':
        return MoveMsg(
          seq: j['seq'] as int? ?? 0,
          player: Stone.fromWire(j['player'] as int),
          x: j['x'] as int,
          y: j['y'] as int,
          isPass: j['pass'] as bool? ?? false,
        );
      case 'resign':
        return ResignMsg(player: Stone.fromWire(j['player'] as int));
      case 'stateRequest':
        return const StateRequest();
      case 'state':
        return StateMsg(
          size: BoardSize.fromLines(j['size'] as int),
          hostColor: Stone.fromWire(j['hostColor'] as int),
          moves: (j['moves'] as List<dynamic>)
              .map((dynamic m) => (m as List<dynamic>)
                  .map((dynamic v) => v as int)
                  .toList())
              .toList(),
        );
      default:
        return null;
    }
  }

  static P2PMessage? decode(String raw) {
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map) return null;
      return P2PMessage.fromJson(j.cast<String, dynamic>());
    } on Object catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}

final class Hello extends P2PMessage {
  const Hello({
    required this.name,
    required this.size,
    required this.hostColor,
    this.protocol = kP2PProtocol,
  });
  final String name;
  final BoardSize size;
  final Player hostColor;
  final int protocol;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': 'hello',
        'protocol': protocol,
        'name': name,
        'size': size.lines,
        'hostColor': hostColor.wire,
      };
}

final class Accept extends P2PMessage {
  const Accept({required this.name});
  final String name;
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'t': 'accept', 'name': name};
}

final class MoveMsg extends P2PMessage {
  const MoveMsg({
    required this.seq,
    required this.player,
    required this.x,
    required this.y,
    this.isPass = false,
  });
  final int seq;
  final Player player;
  final int x;
  final int y;
  final bool isPass;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': 'move',
        'seq': seq,
        'player': player.wire,
        'x': x,
        'y': y,
        'pass': isPass,
      };
}

final class ResignMsg extends P2PMessage {
  const ResignMsg({required this.player});
  final Player player;
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'t': 'resign', 'player': player.wire};
}

final class StateRequest extends P2PMessage {
  const StateRequest();
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'t': 'stateRequest'};
}

/// 전체 상태 — 재연결 시 판을 잃지 않게 한다
final class StateMsg extends P2PMessage {
  const StateMsg({
    required this.size,
    required this.hostColor,
    required this.moves,
  });
  final BoardSize size;
  final Player hostColor;

  /// [x, y, isPass?1:0] 목록
  final List<List<int>> moves;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': 'state',
        'size': size.lines,
        'hostColor': hostColor.wire,
        'moves': moves,
      };
}

enum MultiPhase { lobby, play }

enum MultiError { none, protocolMismatch, outOfTurn, badSequence }

class MultiState {
  const MultiState({
    required this.phase,
    required this.amHost,
    required this.size,
    required this.hostColor,
    required this.myColor,
    required this.connected,
    required this.game,
    required this.seq,
    this.error = MultiError.none,
  });

  factory MultiState.initial({BoardSize size = BoardSize.s9}) => MultiState(
        phase: MultiPhase.lobby,
        amHost: true,
        size: size,
        hostColor: Stone.black,
        myColor: Stone.black,
        connected: false,
        game: createGame(size),
        seq: 0,
      );

  final MultiPhase phase;
  final bool amHost;
  final BoardSize size;
  final Player hostColor;
  final Player myColor;
  final bool connected;
  final GameState game;

  /// 다음에 기대하는 착수 번호 — 순서 어긋남을 잡는다
  final int seq;
  final MultiError error;

  MultiState copyWith({
    MultiPhase? phase,
    bool? amHost,
    BoardSize? size,
    Player? hostColor,
    Player? myColor,
    bool? connected,
    GameState? game,
    int? seq,
    MultiError? error,
  }) =>
      MultiState(
        phase: phase ?? this.phase,
        amHost: amHost ?? this.amHost,
        size: size ?? this.size,
        hostColor: hostColor ?? this.hostColor,
        myColor: myColor ?? this.myColor,
        connected: connected ?? this.connected,
        game: game ?? this.game,
        seq: seq ?? this.seq,
        error: error ?? this.error,
      );
}

sealed class P2PEffect {
  const P2PEffect();
}

final class SendEffect extends P2PEffect {
  const SendEffect(this.message);
  final P2PMessage message;
}

final class SoundEffect extends P2PEffect {
  const SoundEffect();
}

/// 부수효과를 실행하지 않고 목록으로 돌려준다 — 리듀서를 순수하게 유지한다
typedef P2PResult = ({MultiState state, List<P2PEffect> effects});

/// 어긋남 복구 — 호스트가 판의 권위다.
/// 호스트는 자기 판을 그대로 보내고, 게스트는 호스트 판을 요청한다.
/// (양쪽 다 StateRequest 를 보내면 호스트→게스트 요청을 게스트가
/// 응답하지 못해 교착된다 — StateRequest 처리는 호스트 전용이다.)
List<P2PEffect> _resyncEffects(MultiState s) => <P2PEffect>[
      if (s.amHost)
        SendEffect(StateMsg(
          size: s.size,
          hostColor: s.hostColor,
          moves: <List<int>>[
            for (final Move m in s.game.history)
              <int>[m.x, m.y, m.isPass ? 1 : 0],
          ],
        ))
      else
        const SendEffect(StateRequest()),
    ];

P2PResult applyP2PMessage(MultiState s, P2PMessage msg) {
  switch (msg) {
    case StateRequest():
      if (!s.amHost) return (state: s, effects: const <P2PEffect>[]);
      // 진행 중인 판을 그대로 보낸다. 초기화하지 않는다.
      return (
        state: s.copyWith(connected: true, phase: MultiPhase.play),
        effects: <P2PEffect>[
          SendEffect(Hello(
            name: 'host',
            size: s.size,
            hostColor: s.hostColor,
          )),
          SendEffect(StateMsg(
            size: s.size,
            hostColor: s.hostColor,
            moves: <List<int>>[
              for (final Move m in s.game.history)
                <int>[m.x, m.y, m.isPass ? 1 : 0],
            ],
          )),
        ],
      );

    case Hello(:final int protocol, :final BoardSize size, :final Player hostColor):
      if (protocol != kP2PProtocol) {
        // 조용히 매달리지 않고 명시적으로 알린다
        return (
          state: s.copyWith(error: MultiError.protocolMismatch, connected: false),
          effects: const <P2PEffect>[],
        );
      }
      return (
        state: s.copyWith(
          amHost: false,
          size: size,
          hostColor: hostColor,
          myColor: hostColor.opponent,
          game: createGame(size),
          seq: 0,
          connected: true,
          phase: MultiPhase.play,
          error: MultiError.none,
        ),
        effects: <P2PEffect>[const SendEffect(Accept(name: 'guest'))],
      );

    case Accept():
      return (
        state: s.copyWith(
            connected: true, phase: MultiPhase.play, error: MultiError.none),
        effects: const <P2PEffect>[],
      );

    case StateMsg(:final BoardSize size, :final Player hostColor, :final List<List<int>> moves):
      // 재연결 — 전체 수순을 재생해 판을 복원한다
      GameState g = createGame(size);
      for (final List<int> m in moves) {
        final PlayResult r =
            m[2] == 1 ? passMove(g) : tryPlay(g, m[0], m[1]);
        if (r is! PlayOk) break;
        g = r.state;
      }
      return (
        state: s.copyWith(
          size: size,
          hostColor: hostColor,
          myColor: s.amHost ? hostColor : hostColor.opponent,
          game: g,
          seq: moves.length,
          connected: true,
          phase: MultiPhase.play,
          error: MultiError.none,
        ),
        effects: const <P2PEffect>[],
      );

    case MoveMsg(:final int seq, :final Player player, :final int x, :final int y, :final bool isPass):
      if (seq != s.seq) {
        // 어긋났으면 조용히 삼키지 않고 재동기화한다
        return (
          state: s.copyWith(error: MultiError.badSequence),
          effects: _resyncEffects(s),
        );
      }
      if (player != s.game.toPlay) {
        return (
          state: s.copyWith(error: MultiError.outOfTurn),
          effects: _resyncEffects(s),
        );
      }
      final PlayResult r = isPass ? passMove(s.game) : tryPlay(s.game, x, y);
      if (r is! PlayOk) {
        return (
          state: s.copyWith(error: MultiError.badSequence),
          effects: _resyncEffects(s),
        );
      }
      return (
        state: s.copyWith(
            game: r.state, seq: s.seq + 1, error: MultiError.none),
        effects: <P2PEffect>[if (!isPass) const SoundEffect()],
      );

    case ResignMsg(:final Player player):
      return (
        state: s.copyWith(game: resign(s.game, player)),
        effects: const <P2PEffect>[],
      );
  }
}
