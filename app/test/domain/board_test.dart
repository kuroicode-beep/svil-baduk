// test/domain/board_test.dart — src/engine/board.test.ts 이식 + 추가
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/engine/zobrist.dart';

/// 좌표 목록을 순서대로 둔다
GameState play(BoardSize size, List<(int, int)> moves) {
  GameState g = createGame(size);
  for (final (int x, int y) in moves) {
    final PlayResult r = tryPlay(g, x, y);
    if (r is! PlayOk) {
      fail('($x,$y) 착수 실패: ${(r as PlayErr).error}');
    }
    g = r.state;
  }
  return g;
}

void main() {
  group('기본 착수', () {
    test('교대로 둔다', () {
      final GameState g = play(BoardSize.s9, <(int, int)>[(3, 3)]);
      expect(g.toPlay, Stone.white);
      expect(g.stoneAt(3, 3), Stone.black);
      expect(tryPlay(g, 4, 3).ok, isTrue);
    });

    test('같은 자리에 두 번 두지 못한다', () {
      final GameState g = play(BoardSize.s9, <(int, int)>[(3, 3)]);
      final PlayResult r = tryPlay(g, 3, 3);
      expect(r, isA<PlayErr>());
      expect((r as PlayErr).error, MoveError.occupied);
    });

    test('판 밖은 거부', () {
      final GameState g = createGame(BoardSize.s9);
      expect((tryPlay(g, -1, 0) as PlayErr).error, MoveError.outOfBounds);
      expect((tryPlay(g, 9, 0) as PlayErr).error, MoveError.outOfBounds);
    });
  });

  group('따냄', () {
    test('한 점을 따낸다', () {
      // 흑이 (0,0) 백을 둘러싼다
      final GameState g = play(BoardSize.s9, <(int, int)>[
        (1, 0), // B
        (0, 0), // W
        (0, 1), // B — (0,0) 활로 0
      ]);
      expect(g.stoneAt(0, 0), Stone.empty);
      expect(g.blackCaptures, 1);
      expect(g.history.last.captured, <Point>[const Point(0, 0)]);
    });

    test('여러 점을 한꺼번에 따낸다', () {
      // 백 두 점 (0,0),(1,0) 을 흑이 둘러싼다
      GameState g = createGame(BoardSize.s9);
      for (final (int x, int y) in <(int, int)>[
        (2, 0), // B
        (0, 0), // W
        (0, 1), // B
        (1, 0), // W
        (5, 5), // B (여유수)
        (8, 8), // W (여유수)
      ]) {
        g = (tryPlay(g, x, y) as PlayOk).state;
      }
      final PlayResult r = tryPlay(g, 1, 1); // 흑이 마지막 활로를 막는다
      expect(r, isA<PlayOk>());
      final GameState after = (r as PlayOk).state;
      expect(after.stoneAt(0, 0), Stone.empty);
      expect(after.stoneAt(1, 0), Stone.empty);
      expect(after.blackCaptures, 2);
    });

    test('따내는 수는 자살수가 아니다', () {
      // 백 한 점이 흑에 둘러싸여 활로 1 — 흑이 그 활로에 두면 따낸다
      final GameState g = play(BoardSize.s9, <(int, int)>[
        (1, 0), // B
        (0, 0), // W
        (5, 5), // B
        (8, 8), // W
      ]);
      final PlayResult r = tryPlay(g, 0, 1);
      expect(r, isA<PlayOk>());
      expect((r as PlayOk).state.blackCaptures, 1);
    });
  });

  group('자살수', () {
    test('활로 없는 자리에 두지 못한다', () {
      // 백이 (0,0) 을 제외한 모서리를 감싼 상태에서 흑이 (0,0) 에 두면 자살
      GameState g = createGame(BoardSize.s9);
      for (final (int x, int y) in <(int, int)>[
        (5, 5), // B
        (1, 0), // W
        (6, 6), // B
        (0, 1), // W
      ]) {
        g = (tryPlay(g, x, y) as PlayOk).state;
      }
      // 이제 흑 차례, (0,0) 은 활로 0
      final PlayResult r = tryPlay(g, 0, 0);
      expect(r, isA<PlayErr>());
      expect((r as PlayErr).error, MoveError.suicide);
    });
  });

  group('패', () {
    test('되따냄을 즉시 금지한다', () {
      // 표준 패 모양을 배치로 만든다
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(3, 1), Point(2, 2), Point(4, 2), Point(3, 3)],
        white: const <Point>[Point(2, 1), Point(1, 2), Point(2, 3)],
        toPlay: Stone.white,
      );
      // 백이 (3,2) 에 두어 흑 (2,2) 를 따낸다
      final PlayResult take = tryPlay(g, 3, 2);
      expect(take, isA<PlayOk>());
      final GameState afterTake = (take as PlayOk).state;
      expect(afterTake.history.last.captured, <Point>[const Point(2, 2)]);
      expect(afterTake.koPoint, const Point(2, 2));

      // 흑이 바로 되따내려 하면 패로 금지
      final PlayResult back = tryPlay(afterTake, 2, 2);
      expect(back, isA<PlayErr>());
      expect((back as PlayErr).error, MoveError.ko);
    });

    test('다른 곳을 두면 패가 풀린다', () {
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(3, 1), Point(2, 2), Point(4, 2), Point(3, 3)],
        white: const <Point>[Point(2, 1), Point(1, 2), Point(2, 3)],
        toPlay: Stone.white,
      );
      GameState s = (tryPlay(g, 3, 2) as PlayOk).state;
      s = (tryPlay(s, 7, 7) as PlayOk).state; // 흑 팻감
      expect(s.koPoint, isNull);
    });
  });

  group('위치 초과 (superko)', () {
    test('배치 위치를 다시 만드는 수를 막는다', () {
      // 배치 해시가 시딩되지 않으면 이 수가 통과해 버린다 — 회귀 방지
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(3, 1), Point(2, 2), Point(4, 2), Point(3, 3)],
        white: const <Point>[Point(2, 1), Point(1, 2), Point(2, 3)],
        toPlay: Stone.white,
      );
      final GameState afterTake = (tryPlay(g, 3, 2) as PlayOk).state;
      // 패 금지를 우회해도 위치 초과로 걸려야 한다
      final GameState noKo = afterTake.copyWith(clearKo: true);
      final PlayResult back = tryPlay(noKo, 2, 2);
      expect(back, isA<PlayErr>());
      expect((back as PlayErr).error, MoveError.superko);
    });
  });

  group('패스와 종국', () {
    test('두 번 패스로 끝난다', () {
      GameState g = createGame(BoardSize.s9);
      g = (passMove(g) as PlayOk).state;
      expect(g.ended, isFalse);
      expect(g.consecutivePasses, 1);
      g = (passMove(g) as PlayOk).state;
      expect(g.ended, isTrue);
      expect(g.consecutivePasses, 2);
    });

    test('사이에 착수가 있으면 패스 카운트가 초기화된다', () {
      GameState g = createGame(BoardSize.s9);
      g = (passMove(g) as PlayOk).state;
      g = (tryPlay(g, 4, 4) as PlayOk).state;
      expect(g.consecutivePasses, 0);
      g = (passMove(g) as PlayOk).state;
      expect(g.ended, isFalse);
    });

    test('종국 후에는 둘 수 없다', () {
      GameState g = createGame(BoardSize.s9);
      g = (passMove(g) as PlayOk).state;
      g = (passMove(g) as PlayOk).state;
      expect((tryPlay(g, 0, 0) as PlayErr).error, MoveError.gameEnded);
    });

    test('기권하면 상대가 이긴다', () {
      final GameState g = resign(createGame(BoardSize.s9), Stone.black);
      expect(g.ended, isTrue);
      expect(g.resignedBy, Stone.black);
    });
  });

  group('좌표 표기', () {
    test('아래가 1이고 I 를 건너뛴다', () {
      expect(pointLabel(0, 18, 19), 'A1');
      expect(pointLabel(0, 0, 19), 'A19');
      // 19줄 좌상 화점 — 모든 바둑책이 D16 이라 부른다
      expect(pointLabel(3, 3, 19), 'D16');
      expect(pointLabel(3, 15, 19), 'D4');
      expect(pointLabel(7, 0, 9), 'H9');
      expect(pointLabel(8, 0, 9), 'J9');
    });

    test('화점이 표준 위치에 있다', () {
      final List<String> labels = starPoints(BoardSize.s19)
          .map((Point p) => pointLabel(p.x, p.y, 19))
          .toList();
      expect(labels, contains('D16'));
      expect(labels, contains('K10'));
      expect(labels, contains('Q4'));
    });
  });

  group('legalMoves', () {
    test('tryPlay 와 정확히 일치한다', () {
      final GameState g = play(BoardSize.s9, <(int, int)>[(4, 4), (3, 3), (5, 5)]);
      final Set<String> fast =
          legalMoves(g).map((Point p) => '${p.x},${p.y}').toSet();
      for (int y = 0; y < 9; y++) {
        for (int x = 0; x < 9; x++) {
          expect(fast.contains('$x,$y'), tryPlay(g, x, y).ok,
              reason: '($x,$y) 에서 불일치');
        }
      }
      expect(fast.length, 81 - 3);
    });
  });

  group('replayHistory', () {
    test('판·따냄·해시를 정확히 복원한다', () {
      final GameState g = play(BoardSize.s9, <(int, int)>[
        (1, 0), (0, 0), (0, 1), (5, 5), (8, 8), (2, 2),
      ]);
      final GameState replayed = replayHistory(BoardSize.s9, g.history);
      expect(replayed.board, g.board);
      expect(replayed.toPlay, g.toPlay);
      expect(replayed.blackCaptures, g.blackCaptures);
      expect(replayed.zobrist, g.zobrist);
    });
  });

  group('Zobrist', () {
    test('같은 배치는 같은 해시', () {
      final GameState a = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(3, 3), Point(4, 4)],
        white: const <Point>[Point(5, 5)],
        toPlay: Stone.black,
      );
      final GameState b = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(4, 4), Point(3, 3)], // 순서만 다름
        white: const <Point>[Point(5, 5)],
        toPlay: Stone.white, // 차례는 해시에 안 들어간다
      );
      expect(a.zobrist, b.zobrist);
    });

    test('다른 배치는 다른 해시', () {
      final GameState a = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(3, 3)],
        white: const <Point>[],
        toPlay: Stone.black,
      );
      final GameState b = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[],
        white: const <Point>[Point(3, 3)], // 같은 자리, 다른 색
        toPlay: Stone.black,
      );
      expect(a.zobrist, isNot(b.zobrist));
    });

    test('토글은 자기역원이다', () {
      const int h = 12345;
      final int once = Zobrist.toggle(h, 19, 3, 3, Stone.black);
      expect(Zobrist.toggle(once, 19, 3, 3, Stone.black), h);
    });

    test('시드가 고정이라 실행마다 같다', () {
      final Uint8ListLike board = Uint8ListLike(9);
      board.set(3, 3, Stone.black);
      final int h1 = Zobrist.ofBoard(board.data, 9);
      final int h2 = Zobrist.ofBoard(board.data, 9);
      expect(h1, h2);
      expect(h1, isNot(0));
    });
  });
}

/// 테스트 편의용 얇은 래퍼
class Uint8ListLike {
  Uint8ListLike(this.lines) : data = Uint8List(lines * lines);
  final int lines;
  final Uint8List data;
  void set(int x, int y, Stone s) => data[y * lines + x] = s.wire;
}
