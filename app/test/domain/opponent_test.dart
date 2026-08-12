// test/domain/opponent_test.dart — 상대 엔진 통로

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/opponent.dart';
import 'package:svil_baduk/domain/ai/ranks.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

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
}
