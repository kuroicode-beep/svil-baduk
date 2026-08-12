// test/domain/opponent_test.dart — 상대 엔진 통로

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/opponent.dart';
import 'package:svil_baduk/domain/ai/ranks.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

/// 항상 실패하는 상대 — 강등 경로를 재현한다
class _AlwaysFails implements Opponent {
  bool disposed = false;
  @override
  String get labelKey => 'fake';
  @override
  Future<OpponentReply> nextMove(GameState state) async =>
      const OpponentFailed('katagoExited', detail: 'x');
  @override
  void dispose() => disposed = true;
}

void main() {
  test('내장 상대가 합법적인 수를 낸다', () async {
    final BuiltinOpponent o = BuiltinOpponent('lv3');
    GameState g = createGame(BoardSize.s9);
    for (int i = 0; i < 30 && !g.ended; i++) {
      final OpponentReply r = await o.nextMove(g);
      switch (r) {
        case OpponentMove(:final Point point):
          final PlayResult p = tryPlay(g, point.x, point.y);
          expect(p, isA<PlayOk>(), reason: '${i + 1}수째 반칙');
          g = (p as PlayOk).state;
        case OpponentPass():
          g = (passMove(g) as PlayOk).state;
        case OpponentFailed():
          fail('내장 상대는 실패하지 않아야 합니다');
      }
    }
  });

  test('둘 곳이 없으면 패스한다', () async {
    final GameState full = createProblemState(
      size: BoardSize.s9,
      black: <Point>[
        for (int y = 0; y < 9; y++)
          for (int x = 0; x < 9; x++) Point(x, y),
      ],
      white: const <Point>[],
      toPlay: Stone.white,
    );
    expect(await BuiltinOpponent('lv1').nextMove(full), isA<OpponentPass>());
  });

  test('모든 난이도가 답한다', () async {
    for (final RankOption r in kRanks) {
      final OpponentReply reply =
          await BuiltinOpponent(r.id).nextMove(createGame(BoardSize.s9));
      expect(reply, isA<OpponentMove>(), reason: r.id);
    }
  });

  test('라벨 키가 난이도를 따라간다 — 화면에 문자열을 박지 않는다', () {
    expect(BuiltinOpponent('lv7').labelKey, 'rank_lv7');
  });

  test('저장값이 깨져도 기본 난이도로 돈다', () async {
    final OpponentReply r =
        await BuiltinOpponent('없는레벨').nextMove(createGame(BoardSize.s9));
    expect(r, isA<OpponentMove>());
  });

  test('19줄 상위 난이도도 한 수 상한 안에 답한다', () async {
    final Stopwatch sw = Stopwatch()..start();
    await BuiltinOpponent('lv10').nextMove(createGame(BoardSize.s19));
    sw.stop();
    expect(sw.elapsedMilliseconds,
        lessThan(getRank('lv10').maxTime.inMilliseconds),
        reason: '${sw.elapsedMilliseconds}ms');
  });

  group('K7 · 주 엔진이 죽으면 내장 AI 로 이어 둔다', () {
    test('첫 실패에서 강등되고 그 사실을 알린다', () async {
      String? reported;
      final _AlwaysFails dead = _AlwaysFails();
      final FallbackOpponent o = FallbackOpponent(
        primary: dead,
        backup: BuiltinOpponent('lv3'),
        onFallback: (String key, String? _) => reported = key,
      );

      final OpponentReply r = await o.nextMove(createGame(BoardSize.s9));
      expect(r, isA<OpponentMove>(), reason: '강등 후에도 수가 나와야 한다');
      expect(reported, 'katagoExited', reason: '조용히 바뀌면 안 된다');
      expect(o.usingBackup, isTrue);
      expect(dead.disposed, isTrue, reason: '죽은 엔진을 정리하지 않았습니다');
    });

    test('한 번 강등되면 다시 시도하지 않는다 — 매 수 타임아웃을 기다리게 된다', () async {
      int attempts = 0;
      final Opponent counting = _CountingFail(() => attempts++);
      final FallbackOpponent o = FallbackOpponent(
        primary: counting,
        backup: BuiltinOpponent('lv1'),
      );
      GameState g = createGame(BoardSize.s9);
      for (int i = 0; i < 5; i++) {
        final OpponentReply r = await o.nextMove(g);
        if (r is OpponentMove) {
          g = (tryPlay(g, r.point.x, r.point.y) as PlayOk).state;
        }
      }
      expect(attempts, 1);
    });

    test('라벨이 실제로 두는 쪽을 가리킨다', () async {
      final FallbackOpponent o = FallbackOpponent(
        primary: _AlwaysFails(),
        backup: BuiltinOpponent('lv3'),
      );
      expect(o.labelKey, 'fake');
      await o.nextMove(createGame(BoardSize.s9));
      expect(o.labelKey, 'rank_lv3');
    });
  });
}

class _CountingFail implements Opponent {
  _CountingFail(this.onTry);
  final void Function() onTry;
  @override
  String get labelKey => 'fake';
  @override
  Future<OpponentReply> nextMove(GameState state) async {
    onTry();
    return const OpponentFailed('katagoTimeout');
  }
  @override
  void dispose() {}
}
