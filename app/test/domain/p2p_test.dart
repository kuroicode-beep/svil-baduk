// test/domain/p2p_test.dart — 체크리스트 P2·P5·P8
//
// React 판이 문서로만 남겨뒀던 결함들이 실제로 고쳐졌는지 확인한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/p2p/protocol.dart';

MultiState hostInPlay({BoardSize size = BoardSize.s9}) =>
    MultiState.initial(size: size)
        .copyWith(amHost: true, phase: MultiPhase.play, connected: true);

void main() {
  group('메시지 직렬화', () {
    test('모든 종류가 왕복한다', () {
      final List<P2PMessage> all = <P2PMessage>[
        const Hello(name: 'h', size: BoardSize.s13, hostColor: Stone.white),
        const Accept(name: 'g'),
        const MoveMsg(seq: 3, player: Stone.black, x: 4, y: 5),
        const MoveMsg(seq: 4, player: Stone.white, x: -1, y: -1, isPass: true),
        const ResignMsg(player: Stone.black),
        const StateRequest(),
        const StateMsg(
            size: BoardSize.s19, hostColor: Stone.black, moves: <List<int>>[]),
      ];
      for (final P2PMessage m in all) {
        final P2PMessage? back = P2PMessage.decode(m.encode());
        expect(back, isNotNull, reason: m.runtimeType.toString());
        expect(back!.encode(), m.encode(), reason: m.runtimeType.toString());
      }
    });

    test('잡값을 조용히 통과시키지 않는다', () {
      expect(P2PMessage.decode('not json'), isNull);
      expect(P2PMessage.decode('{"t":"unknown"}'), isNull);
      expect(P2PMessage.decode('[]'), isNull);
    });
  });

  group('핸드셰이크', () {
    test('게스트가 호스트 조건을 받아 반대 색을 갖는다', () {
      final P2PResult r = applyP2PMessage(
        MultiState.initial(),
        const Hello(name: 'h', size: BoardSize.s19, hostColor: Stone.black),
      );
      expect(r.state.amHost, isFalse);
      expect(r.state.myColor, Stone.white);
      expect(r.state.size, BoardSize.s19);
      expect(r.state.phase, MultiPhase.play);
      expect(r.effects.single, isA<SendEffect>());
    });

    test('P5 · 프로토콜 불일치는 행이 아니라 오류를 낸다', () {
      final P2PResult r = applyP2PMessage(
        MultiState.initial(),
        const Hello(
            name: 'old', size: BoardSize.s9, hostColor: Stone.black, protocol: 1),
      );
      expect(r.state.error, MultiError.protocolMismatch);
      expect(r.state.connected, isFalse);
      expect(r.state.phase, MultiPhase.lobby);
    });
  });

  group('재연결 — 대표 버그가 고쳐졌는지', () {
    test('state-request 가 진행 중인 판을 보낸다 (초기화하지 않는다)', () {
      // 프로토콜 1 은 여기서 createGame 으로 리셋해 늘 빈 판에서 다시 시작했다
      MultiState s = hostInPlay();
      s = applyP2PMessage(
              s, const MoveMsg(seq: 0, player: Stone.black, x: 3, y: 3))
          .state;
      s = applyP2PMessage(
              s, const MoveMsg(seq: 1, player: Stone.white, x: 5, y: 5))
          .state;
      expect(s.game.history.length, 2);

      final P2PResult r = applyP2PMessage(s, const StateRequest());
      expect(r.state.game.history.length, 2, reason: '판이 유지되어야 합니다');

      final StateMsg sent =
          r.effects.whereType<SendEffect>().last.message as StateMsg;
      expect(sent.moves.length, 2);
    });

    test('전체 상태를 받으면 판을 복원한다', () {
      final P2PResult r = applyP2PMessage(
        MultiState.initial(),
        const StateMsg(
          size: BoardSize.s9,
          hostColor: Stone.black,
          moves: <List<int>>[
            <int>[3, 3, 0],
            <int>[5, 5, 0],
            <int>[-1, -1, 1],
          ],
        ),
      );
      expect(r.state.game.history.length, 3);
      expect(r.state.game.stoneAt(3, 3), Stone.black);
      expect(r.state.game.stoneAt(5, 5), Stone.white);
      expect(r.state.seq, 3);
    });
  });

  group('착수 검증 — 조용히 삼키지 않는다', () {
    test('P2 · 정상 착수를 적용하고 소리를 요청한다', () {
      final P2PResult r = applyP2PMessage(
          hostInPlay(), const MoveMsg(seq: 0, player: Stone.black, x: 3, y: 3));
      expect(r.state.game.history.length, 1);
      expect(r.state.seq, 1);
      expect(r.effects.single, isA<SoundEffect>());
    });

    test('순서가 어긋나면 전체 상태를 다시 요청한다', () {
      // 프로토콜 1 은 이걸 조용히 삼켰다
      final P2PResult r = applyP2PMessage(
          hostInPlay(), const MoveMsg(seq: 7, player: Stone.black, x: 3, y: 3));
      expect(r.state.error, MultiError.badSequence);
      expect(r.state.game.history, isEmpty);
      expect((r.effects.single as SendEffect).message, isA<StateRequest>());
    });

    test('차례가 아닌 쪽의 수를 거부한다', () {
      // 프로토콜 1 은 move.player 를 무시하고 수신자의 toPlay 로 적용했다
      final P2PResult r = applyP2PMessage(
          hostInPlay(), const MoveMsg(seq: 0, player: Stone.white, x: 3, y: 3));
      expect(r.state.error, MultiError.outOfTurn);
      expect(r.state.game.history, isEmpty);
      expect((r.effects.single as SendEffect).message, isA<StateRequest>());
    });

    test('반칙 수도 재동기화로 이어진다', () {
      MultiState s = hostInPlay();
      s = applyP2PMessage(
              s, const MoveMsg(seq: 0, player: Stone.black, x: 3, y: 3))
          .state;
      // 같은 자리
      final P2PResult r = applyP2PMessage(
          s, const MoveMsg(seq: 1, player: Stone.white, x: 3, y: 3));
      expect(r.state.error, MultiError.badSequence);
      expect((r.effects.single as SendEffect).message, isA<StateRequest>());
    });

    test('패스는 소리를 내지 않는다', () {
      final P2PResult r = applyP2PMessage(hostInPlay(),
          const MoveMsg(seq: 0, player: Stone.black, x: -1, y: -1, isPass: true));
      expect(r.state.game.history.single.isPass, isTrue);
      expect(r.effects, isEmpty);
    });
  });

  test('기권이 대국을 끝낸다', () {
    final P2PResult r =
        applyP2PMessage(hostInPlay(), const ResignMsg(player: Stone.white));
    expect(r.state.game.ended, isTrue);
    expect(r.state.game.resignedBy, Stone.white);
  });

  test('리듀서는 순수하다 — 두 번 불러도 두 번 적용되지 않는다', () {
    final MultiState s = hostInPlay();
    const MoveMsg m = MoveMsg(seq: 0, player: Stone.black, x: 3, y: 3);
    expect(applyP2PMessage(s, m).state.game.history.length, 1);
    expect(applyP2PMessage(s, m).state.game.history.length, 1);
    expect(s.game.history, isEmpty);
  });
}
