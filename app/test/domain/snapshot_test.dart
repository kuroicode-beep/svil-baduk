// test/domain/snapshot_test.dart — 체크리스트 G8 (스냅샷 왕복, 패 상태 포함)

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/snapshot.dart';
import 'package:svil_baduk/domain/engine/types.dart';

GameState _randomGame(int seed, BoardSize size, int turns) {
  final math.Random rng = math.Random(seed);
  GameState g = createGame(size);
  for (int i = 0; i < turns && !g.ended; i++) {
    final List<Point> moves = legalMoves(g);
    if (moves.isEmpty) break;
    if (rng.nextInt(25) == 0) {
      g = (passMove(g) as PlayOk).state;
      continue;
    }
    final PlayResult r = tryPlay(g, moves[rng.nextInt(moves.length)].x,
        moves[rng.nextInt(moves.length)].y);
    if (r is PlayOk) g = r.state;
  }
  return g;
}

void main() {
  group('G8 · 왕복', () {
    test('무작위 대국 100판이 완전히 복원된다', () {
      for (int seed = 0; seed < 100; seed++) {
        final GameState g = _randomGame(seed, BoardSize.values[seed % 3], 45);
        final SnapshotResult r = decodeSnapshot(encodeSnapshot(g));
        expect(r, isA<SnapshotOk>(), reason: 'seed $seed');
        final GameState back = (r as SnapshotOk).state;

        expect(back.board, g.board, reason: 'seed $seed');
        expect(back.zobrist, g.zobrist, reason: 'seed $seed');
        expect(back.toPlay, g.toPlay, reason: 'seed $seed');
        expect(back.blackCaptures, g.blackCaptures, reason: 'seed $seed');
        expect(back.whiteCaptures, g.whiteCaptures, reason: 'seed $seed');
        expect(back.consecutivePasses, g.consecutivePasses, reason: 'seed $seed');
        expect(back.ended, g.ended, reason: 'seed $seed');
      }
    });

    test('⚠ 패 금지점이 복원된다 — 판만 저장하면 사라지는 정보다', () {
      // 교과서 패 모양 (x 오른쪽, y 아래)
      //   y=0   .  흑  백  .
      //   y=1  흑  백  .  백
      //   y=2   .  흑  백  .
      GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(1, 0), Point(0, 1), Point(1, 2)],
        white: const <Point>[Point(2, 0), Point(1, 1), Point(3, 1), Point(2, 2)],
        toPlay: Stone.black,
      );
      // 흑이 (2,1) 에 두어 백 (1,1) 을 따낸다 → (1,1) 이 패 금지점이 된다
      final PlayResult r = tryPlay(g, 2, 1);
      expect(r, isA<PlayOk>(), reason: '패 모양 구성 실패');
      g = (r as PlayOk).state;
      expect(g.koPoint, isNotNull, reason: '패 금지점이 생기지 않았습니다');

      final GameState back = (decodeSnapshot(encodeSnapshot(g)) as SnapshotOk).state;
      expect(back.koPoint?.x, g.koPoint!.x);
      expect(back.koPoint?.y, g.koPoint!.y);
      // 되따냄이 양쪽에서 똑같이 막혀야 한다
      expect(tryPlay(back, g.koPoint!.x, g.koPoint!.y), isA<PlayErr>());
    });

    test('슈퍼코 이력이 복원된다', () {
      final GameState g = _randomGame(11, BoardSize.s9, 60);
      final GameState back = (decodeSnapshot(encodeSnapshot(g)) as SnapshotOk).state;
      // 이력이 살아 있으면 같은 수에 같은 판정이 나온다
      for (final Point p in legalMoves(g)) {
        expect(tryPlay(back, p.x, p.y) is PlayOk, isTrue,
            reason: '원본에서 합법인 ${p.x},${p.y} 가 복원본에서 막혔습니다');
      }
      expect(legalMoves(back).length, legalMoves(g).length);
    });

    test('배치 문제에서 이어 둔 대국도 복원된다', () {
      GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(4, 4), Point(3, 3)],
        white: const <Point>[Point(5, 5)],
        toPlay: Stone.black,
      );
      g = (tryPlay(g, 6, 6) as PlayOk).state;
      final GameState back = (decodeSnapshot(encodeSnapshot(g)) as SnapshotOk).state;
      expect(back.board, g.board, reason: '초기 배치가 사라졌습니다');
      expect(back.initialBoard, g.initialBoard);
    });

    test('기권이 복원된다', () {
      final GameState g = resign(_randomGame(2, BoardSize.s9, 20), Stone.white);
      final GameState back = (decodeSnapshot(encodeSnapshot(g)) as SnapshotOk).state;
      expect(back.resignedBy, Stone.white);
      expect(back.ended, isTrue);
    });

    test('두 번 패스로 끝난 대국도 끝난 채로 복원된다', () {
      GameState g = _randomGame(6, BoardSize.s9, 20);
      g = (passMove(g) as PlayOk).state;
      g = (passMove(g) as PlayOk).state;
      expect(g.ended, isTrue);
      expect((decodeSnapshot(encodeSnapshot(g)) as SnapshotOk).state.ended, isTrue);
    });
  });

  group('손상된 데이터를 조용히 받아들이지 않는다', () {
    test('JSON 이 아니면 거절', () {
      expect((decodeSnapshot('{{{') as SnapshotFail).reasonKey, 'snapshotCorrupt');
      expect((decodeSnapshot('[]') as SnapshotFail).reasonKey, 'snapshotCorrupt');
    });

    test('앞으로 나온 형식은 추측하지 않고 거절', () {
      final SnapshotFail f = decodeSnapshot(
          '{"version":99,"size":9,"moves":[]}') as SnapshotFail;
      expect(f.reasonKey, 'snapshotTooNew');
      expect(f.detail, '99');
    });

    test('지원하지 않는 판 크기', () {
      expect(
          (decodeSnapshot('{"version":1,"size":7,"moves":[]}') as SnapshotFail)
              .reasonKey,
          'snapshotBadSize');
    });

    test('재생 불가능한 수는 몇 수째인지 알려준다', () {
      final SnapshotFail f = decodeSnapshot(
              '{"version":1,"size":9,"moves":[{"x":0,"y":0},{"x":0,"y":0}]}')
          as SnapshotFail;
      expect(f.reasonKey, 'snapshotReplayFailed');
      expect(f.detail, '2', reason: '2수째가 같은 자리다');
    });

    test('범위 밖 좌표도 잡는다', () {
      expect(
          (decodeSnapshot('{"version":1,"size":9,"moves":[{"x":99,"y":0}]}')
                  as SnapshotFail)
              .reasonKey,
          'snapshotReplayFailed');
    });

    test('초기 판 길이가 안 맞으면 거절', () {
      expect(
          (decodeSnapshot('{"version":1,"size":9,"initial":[0,0],"moves":[]}')
                  as SnapshotFail)
              .reasonKey,
          'snapshotCorrupt');
    });

    test('initial 이 없는 예전 데이터는 빈 판으로 읽는다', () {
      final SnapshotResult r =
          decodeSnapshot('{"version":1,"size":9,"moves":[{"x":4,"y":4}]}');
      expect(r, isA<SnapshotOk>());
      expect((r as SnapshotOk).state.history.length, 1);
    });
  });
}
