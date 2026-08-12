// test/domain/katago_opponent_test.dart — 체크리스트 K2·K4·K5
//
// KataGo 설치본 없이 검증할 수 있는 부분: 어떤 명령을 몇 번 보내는지.
// 수마다 재동기화하면 GPU 에서도 체감될 만큼 느려지므로, 명령 수를 센다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/katago_opponent.dart';
import 'package:svil_baduk/application/opponent.dart';
import 'package:svil_baduk/data/platform/katago_process.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/gtp_coord.dart';
import 'package:svil_baduk/domain/engine/types.dart';

/// 보낸 명령을 기록하고 정해진 답을 돌려주는 가짜 엔진
class FakeGtp implements GtpChannel {
  FakeGtp({this.genmoveReplies = const <String>[], this.failWith});

  final List<String> sent = <String>[];
  final List<String> genmoveReplies;
  final KataGoException? failWith;
  int _replyIndex = 0;
  bool stopped = false;

  List<String> get plays =>
      sent.where((String c) => c.startsWith('play ')).toList();
  int count(String prefix) =>
      sent.where((String c) => c.startsWith(prefix)).length;

  @override
  Future<String> send(String command, {Duration? timeout}) async {
    if (failWith != null) throw failWith!;
    sent.add(command);
    return '';
  }

  @override
  Future<String> genmove(String color) async {
    if (failWith != null) throw failWith!;
    sent.add('genmove $color');
    if (_replyIndex < genmoveReplies.length) {
      return genmoveReplies[_replyIndex++];
    }
    return 'pass';
  }

  @override
  Future<void> stop() async => stopped = true;
}

/// n수 진행한 판을 만든다 (사람 흑 / 엔진 백 이 번갈아 두는 형태)
GameState _game(int moves, [BoardSize size = BoardSize.s19]) {
  GameState g = createGame(size);
  for (int i = 0; i < moves; i++) {
    final List<Point> ms = legalMoves(g);
    g = (tryPlay(g, ms[i * 7 % ms.length].x, ms[i * 7 % ms.length].y) as PlayOk)
        .state;
  }
  return g;
}

void main() {
  group('K4 · 증분 동기화', () {
    test('100수 대국에 play 명령이 102회를 넘지 않는다', () async {
      // 사람은 위쪽 줄, 엔진은 아래쪽 줄에만 둔다. 겹치면 착수가 거절돼
      // 재동기화가 일어나고, 그건 이 테스트가 재려는 것이 아니다
      // (거절 상황은 아래 K5 에서 따로 본다).
      Point humanAt(int i) => Point(i % 19, i ~/ 19);
      Point engineAt(int i) => Point(i % 19, 18 - i ~/ 19);

      final FakeGtp gtp = FakeGtp(
        genmoveReplies: <String>[
          for (int i = 0; i < 50; i++)
            toGtpCoord(engineAt(i).x, engineAt(i).y, 19),
        ],
      );
      final KataGoOpponent o = KataGoOpponent(gtp, 'lv5');

      GameState g = createGame(BoardSize.s19);
      int humanPly = 0;
      for (int turn = 0; turn < 100 && !g.ended; turn++) {
        if (g.toPlay == Stone.black) {
          final Point p = humanAt(humanPly++);
          g = (tryPlay(g, p.x, p.y) as PlayOk).state;
        } else {
          final OpponentReply r = await o.nextMove(g);
          expect(r, isA<OpponentMove>(), reason: '$turn수째');
          final Point p = (r as OpponentMove).point;
          g = (tryPlay(g, p.x, p.y) as PlayOk).state;
        }
      }

      expect(g.history.length, 100, reason: '100수를 채우지 못했습니다');
      expect(gtp.count('play'), lessThanOrEqualTo(102),
          reason: 'play ${gtp.count('play')}회 — 수마다 재동기화하고 있습니다');
      expect(gtp.count('clear_board'), 1, reason: '분기가 없었는데 재동기화했습니다');
    });

    test('이어지는 수는 새로 둔 것만 보낸다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D4', 'Q16']);
      final KataGoOpponent o = KataGoOpponent(gtp, 'lv5');

      final GameState a = _game(1);
      await o.nextMove(a);
      final int afterFirst = gtp.count('play');

      // 앞 수순을 그대로 유지한 채 두 수 더 진행
      GameState b = a;
      for (int i = 0; i < 2; i++) {
        final List<Point> ms = legalMoves(b);
        b = (tryPlay(b, ms[i].x, ms[i].y) as PlayOk).state;
      }
      await o.nextMove(b);

      // 새로 보낸 play 는 2개 + 엔진 자기 수 1개 이하
      expect(gtp.count('play') - afterFirst, lessThanOrEqualTo(3));
    });
  });

  group('K5 · 분기 시 전체 재동기화 정확히 1회', () {
    test('엔진 수가 거절되면 다음 차례에 한 번 재동기화한다', () async {
      // genmove 는 엔진 판에도 돌을 놓는다. 그 수를 우리가 못 받으면
      // 두 판이 갈라지므로 반드시 맞춰야 한다.
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D4', 'Q16']);
      final KataGoOpponent o = KataGoOpponent(gtp, 'lv5');

      final GameState g = _game(1);
      await o.nextMove(g);
      final int before = gtp.count('clear_board');

      // 엔진 수를 적용하지 않고 사람이 다른 수를 둔 상태로 다시 부른다
      final List<Point> ms = legalMoves(g);
      final GameState diverged = (tryPlay(g, ms.first.x, ms.first.y) as PlayOk).state;
      await o.nextMove(diverged);

      expect(gtp.count('clear_board') - before, 1,
          reason: '갈라진 판을 맞추지 않았거나 두 번 맞췄습니다');
    });

    test('무르면 clear_board 를 한 번만 보낸다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D4', 'Q16']);
      final KataGoOpponent o = KataGoOpponent(gtp, 'lv5');

      final GameState long = _game(6);
      await o.nextMove(long);
      final int before = gtp.count('clear_board');

      // 3수까지 무른다 — 엔진이 아는 수순과 갈라진다
      final GameState shorter = replayHistory(long.size, long.history.take(3).toList());
      await o.nextMove(shorter);

      expect(gtp.count('clear_board') - before, 1);
    });

    test('판 크기가 바뀌면 boardsize 를 다시 보낸다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D4', 'E5']);
      final KataGoOpponent o = KataGoOpponent(gtp, 'lv5');

      await o.nextMove(_game(1, BoardSize.s19));
      await o.nextMove(_game(1, BoardSize.s9));

      expect(gtp.sent.where((String c) => c == 'boardsize 19').length, 1);
      expect(gtp.sent.where((String c) => c == 'boardsize 9').length, 1);
    });

    test('난이도가 탐색량으로 전달된다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D4']);
      await KataGoOpponent(gtp, 'lv10').nextMove(_game(1));
      expect(gtp.sent, contains('kata-set-param maxVisits 320'));
    });
  });

  group('K2 · 오류가 서로 구별된다', () {
    test('9가지 오류가 모두 다른 i18n 키를 가진다', () {
      final Set<String> keys =
          KataGoError.values.map(kataGoErrorKey).toSet();
      expect(keys.length, KataGoError.values.length);
    });

    test('엔진 실패는 조용히 넘어가지 않고 사유를 돌려준다', () async {
      final FakeGtp gtp = FakeGtp(
          failWith: const KataGoException(KataGoError.timeout, 'genmove B'));
      final OpponentReply r =
          await KataGoOpponent(gtp, 'lv5').nextMove(_game(1));
      expect(r, isA<OpponentFailed>());
      expect((r as OpponentFailed).reasonKey, 'katagoTimeout');
      expect(r.detail, 'genmove B');
    });

    test('해석 불가 응답도 실패로 보고한다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['ZZ99']);
      final OpponentReply r =
          await KataGoOpponent(gtp, 'lv5').nextMove(_game(1));
      expect(r, isA<OpponentFailed>());
      expect((r as OpponentFailed).detail, 'ZZ99');
    });
  });

  group('응답 해석', () {
    test('좌표 응답이 판 좌표로 온다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['D16']);
      final OpponentReply r =
          await KataGoOpponent(gtp, 'lv5').nextMove(_game(1));
      expect(r, isA<OpponentMove>());
      expect((r as OpponentMove).point, const Point(3, 3));
    });

    test('pass 와 resign 은 패스로 받는다', () async {
      for (final String reply in <String>['pass', 'resign']) {
        final FakeGtp gtp = FakeGtp(genmoveReplies: <String>[reply]);
        expect(await KataGoOpponent(gtp, 'lv5').nextMove(_game(1)),
            isA<OpponentPass>(), reason: reply);
      }
    });

    test('보낸 좌표가 사람이 듣는 좌표와 같다', () async {
      final FakeGtp gtp = FakeGtp(genmoveReplies: const <String>['pass']);
      final GameState g = (tryPlay(createGame(BoardSize.s19), 3, 3) as PlayOk).state;
      await KataGoOpponent(gtp, 'lv5').nextMove(g);
      expect(gtp.plays, contains('play B D16'));
      expect(pointLabel(3, 3, 19), 'D16');
    });
  });

  test('K8 · dispose 가 프로세스를 내린다 (고아 방지)', () {
    final FakeGtp gtp = FakeGtp();
    KataGoOpponent(gtp, 'lv5').dispose();
    expect(gtp.stopped, isTrue);
  });
}
