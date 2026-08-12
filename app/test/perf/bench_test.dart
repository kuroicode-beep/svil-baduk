// test/perf/bench_test.dart — 체크리스트 F2·F4 실측
//
// 임계값을 넉넉히 잡았다. CI 머신은 느릴 수 있고, 이 테스트의 목적은
// 성능 회귀를 잡는 것이지 특정 하드웨어를 증명하는 게 아니다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

void main() {
  test('F2 · 빈 19줄 legalMoves 가 15ms 이내', () {
    final GameState g = createGame(BoardSize.s19);
    legalMoves(g); // 워밍업
    final Stopwatch sw = Stopwatch()..start();
    const int runs = 20;
    for (int i = 0; i < runs; i++) {
      legalMoves(g);
    }
    sw.stop();
    final double each = sw.elapsedMicroseconds / runs / 1000;
    // ignore: avoid_print
    expect(each, lessThan(15.0),
        reason: 'legalMoves ${each.toStringAsFixed(2)}ms (기준 15ms)');
  });

  test('F4 · 19줄 착수가 16ms 이내', () {
    GameState g = createGame(BoardSize.s19);
    // 실전에 가깝게 100수 진행한 판에서 잰다
    for (int i = 0; i < 100; i++) {
      final List<Point> ms = legalMoves(g);
      final Point p = ms[(i * 37) % ms.length];
      final PlayResult r = tryPlay(g, p.x, p.y);
      if (r is PlayOk) g = r.state;
    }
    final Stopwatch sw = Stopwatch()..start();
    const int runs = 50;
    for (int i = 0; i < runs; i++) {
      tryPlay(g, 0, 0);
    }
    sw.stop();
    final double each = sw.elapsedMicroseconds / runs / 1000;
    expect(each, lessThan(16.0),
        reason: 'tryPlay ${each.toStringAsFixed(2)}ms (기준 16ms)');
  });

  test('legalMoves 가 판 크기에 따라 폭발하지 않는다', () {
    final Map<BoardSize, double> times = <BoardSize, double>{};
    for (final BoardSize size in BoardSize.values) {
      final GameState g = createGame(size);
      legalMoves(g);
      final Stopwatch sw = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        legalMoves(g);
      }
      sw.stop();
      times[size] = sw.elapsedMicroseconds / 10 / 1000;
    }
    // 19줄이 9줄의 30배를 넘으면 알고리즘이 잘못된 것이다 (면적비는 4.5배)
    expect(times[BoardSize.s19]!, lessThan(times[BoardSize.s9]! * 30 + 5),
        reason: times.toString());
  });
}
