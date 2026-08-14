// test/domain/multi_controller_test.dart — P2P 세션 두뇌 (체크리스트 P2·P5)
//
// 루프백 전송으로 컨트롤러 두 개를 실제 핸드셰이크부터 잇는다.
// 네트워크 없이 프로토콜 전체(접속→색 배정→교차 착수→재동기화→기권)를 돈다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/game_controller.dart';
import 'package:svil_baduk/application/multi_controller.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/p2p/protocol.dart';

import '../support/loopback_p2p.dart';
import '../support/speech_fixture.dart';

GameController makeGame(BoardSize size) => GameController(
      size: size,
      speech: testSpeech,
      moveErrorPhrase: (MoveError e) => e.name,
      coordErrorPhrase: (_, int lines) => '입력 오류',
    );

void main() {
  late FakeBrokerRegistry registry;
  late FakeEndpoint hostEp;
  late FakeEndpoint guestEp;
  late MultiController host;
  late MultiController guest;
  final List<MultiSessionEvent> hostEvents = <MultiSessionEvent>[];
  final List<MultiSessionEvent> guestEvents = <MultiSessionEvent>[];

  Future<void> connectPair({BoardSize size = BoardSize.s9}) async {
    registry = FakeBrokerRegistry();
    hostEvents.clear();
    guestEvents.clear();
    hostEp = FakeEndpoint(registry, fixedId: 'svb-host77');
    guestEp = FakeEndpoint(registry, fixedId: 'svb-guest77');
    host = MultiController(
      endpoint: hostEp,
      makeGame: makeGame,
      onSession: hostEvents.add,
    )..size = size;
    guest = MultiController(
      endpoint: guestEp,
      makeGame: makeGame,
      onSession: guestEvents.add,
    );
    await host.openRoom();
    await guest.openRoom();
    await guest.join('svb-host77');
    await pumpEventQueue();
  }

  test('핸드셰이크 — 게스트가 호스트 조건으로 대국에 들어간다', () async {
    await connectPair(size: BoardSize.s13);

    expect(host.phase, MultiScreenPhase.play);
    expect(guest.phase, MultiScreenPhase.play);
    expect(host.myColor, Stone.black);
    expect(guest.myColor, Stone.white);
    expect(guest.game.state.size, BoardSize.s13,
        reason: '게스트 판 크기는 호스트가 정한다');
    expect(hostEvents.whereType<MultiStarted>(), isNotEmpty);
    expect(guestEvents.whereType<MultiStarted>(), isNotEmpty);
  });

  test('P2 · 교차 착수 5수 — 두 판이 같은 국면을 가진다', () async {
    await connectPair();

    final List<(MultiController, int, int)> moves =
        <(MultiController, int, int)>[
      (host, 2, 2),
      (guest, 6, 6),
      (host, 2, 6),
      (guest, 6, 2),
      (host, 4, 4),
    ];
    for (final (MultiController who, int x, int y) in moves) {
      expect(who.myTurn, isTrue, reason: '($x,$y) 차례가 아니다');
      final PlayOutcome o = who.placeAt(x, y);
      expect(o, isA<PlayedMove>());
      await pumpEventQueue();
    }

    expect(host.game.state.history.length, 5);
    expect(guest.game.state.history.length, 5);
    expect(host.game.state.zobrist, guest.game.state.zobrist,
        reason: '두 판의 국면 해시가 같아야 한다');
    // 원격 수는 낭독 문장을 실어 화면에 전달된다
    expect(guestEvents.whereType<MultiRemoteOutcome>().length, 3);
    expect(hostEvents.whereType<MultiRemoteOutcome>().length, 2);
  });

  test('패스 왕복 두 번이면 종국이 양쪽에 선다', () async {
    await connectPair();
    host.placeAt(4, 4);
    await pumpEventQueue();
    guest.placeAt(2, 2);
    await pumpEventQueue();
    expect(host.passTurn(), isA<PlayedMove>());
    await pumpEventQueue();
    expect(guest.passTurn(), isA<GameEnded>());
    await pumpEventQueue();
    expect(host.game.state.ended, isTrue);
    expect(guest.game.state.ended, isTrue);
  });

  test('기권이 상대 판까지 끝낸다', () async {
    await connectPair();
    final PlayOutcome o = guest.resignMine();
    expect(o, isA<GameEnded>());
    await pumpEventQueue();
    expect(host.game.state.ended, isTrue);
    expect(host.game.state.resignedBy, Stone.white);
    expect(hostEvents.whereType<MultiRemoteOutcome>().single.outcome,
        isA<GameEnded>());
  });

  test('시퀀스 어긋남 — 호스트가 권위 판을 보내 게스트가 복원한다', () async {
    await connectPair();
    host.placeAt(4, 4);
    await pumpEventQueue();

    // 호스트 수신 채널로 엉뚱한 seq 를 주입한다 (전송 중복·유실 시나리오)
    final LoopbackTransport hostSide = hostEp.transports.single;
    hostSide.inject(
        const MoveMsg(seq: 9, player: Stone.white, x: 5, y: 5).encode());
    await pumpEventQueue();

    // 호스트는 StateMsg 를 보냈고, 게스트 판은 호스트와 같다
    expect(hostSide.sent.any((String s) => s.contains('"t":"state"')), isTrue);
    expect(guest.game.state.zobrist, host.game.state.zobrist);
    expect(guest.game.state.history.length, 1);
  });

  test('P5 · 프로토콜 불일치는 행이 아니라 오류 사건이 된다', () async {
    await connectPair();
    final LoopbackTransport guestSide = guestEp.transports.single;
    guestSide.inject(
        '{"t":"hello","protocol":1,"name":"old","size":9,"hostColor":1}');
    await pumpEventQueue();
    expect(
      guestEvents.whereType<MultiTrouble>().any(
          (MultiTrouble t) => t.reasonKey == 'protocolMismatch'),
      isTrue,
    );
  });

  test('내 차례가 아니면 착수 입력이 실패로 돌아온다 (A12 경로 유지)', () async {
    await connectPair();
    // 첫 수는 흑(호스트) — 게스트가 두려 하면 거절
    final PlayOutcome o = guest.submitInput(
      'C3',
      notYourTurnPhrase: '지금은 상대 차례입니다',
      notAvailablePhrase: '함께 두기에서는 무르기·힌트를 쓸 수 없습니다',
    );
    expect(o, isA<InputError>());
    expect((o as InputError).speech, '지금은 상대 차례입니다');
    expect(guest.game.state.history, isEmpty);
  });

  test('무르기·힌트는 함께 두기에서 막힌다', () async {
    await connectPair();
    for (final String cmd in <String>['무르기', 'undo', '힌트', 'hint']) {
      final PlayOutcome o = host.submitInput(
        cmd,
        notYourTurnPhrase: '차례 아님',
        notAvailablePhrase: '멀티 불가',
      );
      expect(o, isA<InputError>(), reason: cmd);
      expect((o as InputError).speech, '멀티 불가', reason: cmd);
    }
  });

  test('연결이 끊기면 사건이 오르고 myTurn 이 꺼진다', () async {
    await connectPair();
    await guestEp.transports.single.close();
    await pumpEventQueue();
    expect(host.connected, isFalse);
    expect(guest.connected, isFalse);
    expect(host.myTurn, isFalse);
    expect(
      hostEvents.whereType<MultiTrouble>().any(
          (MultiTrouble t) => t.reasonKey == 'disconnected'),
      isTrue,
    );
  });

  test('늦게 온 두 번째 손님은 받지 않는다', () async {
    await connectPair();
    final MultiController third = MultiController(
      endpoint: FakeEndpoint(registry, fixedId: 'svb-third77'),
      makeGame: makeGame,
    );
    await third.openRoom();
    await third.join('svb-host77');
    await pumpEventQueue();
    expect(third.phase, MultiScreenPhase.lobby,
        reason: '호스트가 받지 않으므로 로비로 되돌아온다');
    expect(host.game.state.history, isEmpty);
    third.dispose();
  });
}
