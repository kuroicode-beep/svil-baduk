// test/domain/capture_points_test.dart — 최적화가 동작을 바꾸지 않았음을 고정한다
//
// capturePoints 는 내장 AI 의 O(n²) 병목을 없애려고 도입했다.
// "전 합법수를 두어 보고 따냄이 생기는지 세는" 원래 방식과
// 결과가 정확히 같아야 의미가 있다. 그걸 여기서 무작위 판으로 확인한다.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

/// 원래 방식 — 느리지만 정의 그대로다
Set<Point> _byBruteForce(GameState state) {
  final Set<Point> out = <Point>{};
  for (final Point m in legalMoves(state)) {
    final PlayResult r = tryPlay(state, m.x, m.y);
    if (r is PlayOk && r.move.captured.isNotEmpty) out.add(m);
  }
  return out;
}

void main() {
  test('무작위 실전 판 300개에서 전수 시뮬레이션과 완전히 일치', () {
    int boardsWithCaptures = 0;

    for (int seed = 0; seed < 300; seed++) {
      final math.Random rng = math.Random(seed);
      GameState g = createGame(BoardSize.s9);

      // 무작위로 진행하다 중간중간 비교한다
      for (int turn = 0; turn < 60 && !g.ended; turn++) {
        final List<Point> moves = legalMoves(g);
        if (moves.isEmpty) break;
        final PlayResult r =
            tryPlay(g, moves[rng.nextInt(moves.length)].x, moves[rng.nextInt(moves.length)].y);
        if (r is PlayOk) g = r.state;

        if (turn % 7 == 0) {
          final Set<Point> fast = capturePoints(g);
          final Set<Point> slow = _byBruteForce(g);
          if (slow.isNotEmpty) boardsWithCaptures++;
          expect(
            fast.map((Point p) => '${p.x},${p.y}').toSet(),
            slow.map((Point p) => '${p.x},${p.y}').toSet(),
            reason: 'seed $seed, $turn수째',
          );
        }
      }
    }

    // 전부 빈 집합이라 통과한 것이라면 검증이 아니다
    expect(boardsWithCaptures, greaterThan(50),
        reason: '따냄이 가능한 국면이 $boardsWithCaptures 개뿐이라 비교가 무의미합니다');
  });

  test('활로 1개인 그룹의 그 활로가 따냄 점이다', () {
    // 백 한 점이 3면 포위 — (0,0) 이 마지막 활로
    final GameState g = createProblemState(
      size: BoardSize.s9,
      black: const <Point>[Point(2, 0), Point(1, 1)],
      white: const <Point>[Point(1, 0)],
      toPlay: Stone.black,
    );
    expect(capturePoints(g), <Point>{const Point(0, 0)});
  });

  test('빈 판에는 따낼 것이 없다', () {
    for (final BoardSize s in BoardSize.values) {
      expect(capturePoints(createGame(s)), isEmpty, reason: '${s.lines}줄');
    }
  });

  test('19줄에서도 빠르다 — 이 최적화의 목적', () {
    GameState g = createGame(BoardSize.s19);
    final math.Random rng = math.Random(7);
    for (int i = 0; i < 120; i++) {
      final List<Point> moves = legalMoves(g);
      final PlayResult r = tryPlay(g, moves[rng.nextInt(moves.length)].x,
          moves[rng.nextInt(moves.length)].y);
      if (r is PlayOk) g = r.state;
    }
    final Stopwatch sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      capturePoints(g);
    }
    sw.stop();
    final double each = sw.elapsedMicroseconds / 100 / 1000;
    expect(each, lessThan(5.0), reason: 'capturePoints ${each.toStringAsFixed(2)}ms');
  });
}
