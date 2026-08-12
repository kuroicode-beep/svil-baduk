// test/domain/sgf_test.dart — 체크리스트 G9 (SGF 왕복)

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/sgf.dart';
import 'package:svil_baduk/domain/engine/types.dart';

GameState _randomGame(int seed, BoardSize size, int turns) {
  final math.Random rng = math.Random(seed);
  GameState g = createGame(size);
  for (int i = 0; i < turns && !g.ended; i++) {
    final List<Point> moves = legalMoves(g);
    if (moves.isEmpty) break;
    // 가끔 패스를 섞는다 — 패스가 있는 기보도 왕복해야 한다
    if (rng.nextInt(20) == 0) {
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
  group('G9 · 왕복', () {
    test('무작위 대국 100판이 판·따냄·수순까지 그대로 복원된다', () {
      for (int seed = 0; seed < 100; seed++) {
        final BoardSize size = BoardSize.values[seed % 3];
        final GameState original = _randomGame(seed, size, 50);
        final SgfResult back = decodeSgf(encodeSgf(original));

        expect(back, isA<SgfOk>(), reason: 'seed $seed 해석 실패');
        final GameState restored = (back as SgfOk).state;

        expect(restored.size, original.size, reason: 'seed $seed');
        expect(restored.board, original.board, reason: 'seed $seed 판 불일치');
        expect(restored.blackCaptures, original.blackCaptures, reason: 'seed $seed');
        expect(restored.whiteCaptures, original.whiteCaptures, reason: 'seed $seed');
        expect(restored.history.length, original.history.length, reason: 'seed $seed');
        expect(restored.toPlay, original.toPlay, reason: 'seed $seed');
        expect(restored.zobrist, original.zobrist, reason: 'seed $seed 해시 불일치');
      }
    });

    test('두 번 왕복해도 같은 문자열 (안정적이다)', () {
      final GameState g = _randomGame(7, BoardSize.s19, 60);
      final String once = encodeSgf(g);
      final String twice = encodeSgf((decodeSgf(once) as SgfOk).state);
      expect(twice, once);
    });

    test('대국자 이름이 실려 나가고 특수문자가 이스케이프된다', () {
      final String s = encodeSgf(createGame(BoardSize.s9),
          black: r'인블루', white: r'a]b\c');
      expect(s, contains('PB[인블루]'));
      expect(s, contains(r'PW[a\]b\\c]'));
    });

    test('빈 판도 유효한 SGF 다', () {
      final String s = encodeSgf(createGame(BoardSize.s13));
      expect(s, startsWith('(;FF[4]GM[1]SZ[13]'));
      expect((decodeSgf(s) as SgfOk).state.history, isEmpty);
    });

    test('버전을 박아넣지 않는다 — AP 는 실제 앱 버전을 쓴다', () {
      expect(encodeSgf(createGame(BoardSize.s9)), isNot(contains('AP[SVIL-Baduk:0.3]')));
    });
  });

  group('거절 사유가 구별된다 (침묵 금지)', () {
    test('SGF 가 아니면 notSgf', () {
      expect((decodeSgf('그냥 텍스트') as SgfFail).error, SgfError.notSgf);
    });

    test('지원하지 않는 판 크기', () {
      final SgfFail f = decodeSgf('(;FF[4]SZ[21])') as SgfFail;
      expect(f.error, SgfError.unsupportedSize);
      expect(f.detail, '21');
    });

    test('차례가 어긋나면 turnMismatch — 몇 수째인지 알려준다', () {
      final SgfFail f = decodeSgf('(;FF[4]SZ[9];W[aa])') as SgfFail;
      expect(f.error, SgfError.turnMismatch);
      expect(f.detail, contains('1수째'));
    });

    test('반칙 수는 illegalMove — 사람이 읽는 좌표로 알려준다', () {
      // 같은 자리에 두 번
      final SgfFail f = decodeSgf('(;FF[4]SZ[9];B[cc];W[dd];B[cc])') as SgfFail;
      expect(f.error, SgfError.illegalMove);
      expect(f.detail, contains('3수째'));
    });

    test('⚠ 대문자 좌표를 패스로 삼키지 않는다 (TS 판의 조용한 손상)', () {
      // 대문자는 26줄 초과 판용이라 9줄 기보에서는 오류다.
      // 정규식이 대소문자를 무시하고 해석 실패를 패스로 처리하면
      // 이 기보가 "패스 2번으로 끝난 대국" 이 되어 통과해 버린다.
      final SgfResult r = decodeSgf('(;FF[4]SZ[9];B[AA];W[BB])');
      expect(r, isA<SgfFail>());
      if (r is SgfOk) {
        fail('대문자 좌표가 조용히 받아들여졌습니다 — 수 ${r.state.history.length}개');
      }
    });

    test('한 글자 좌표도 거절한다', () {
      expect((decodeSgf('(;FF[4]SZ[9];B[a])') as SgfFail).error, SgfError.badCoord);
    });

    test("빈 값과 'tt' 만 패스다", () {
      final GameState a = (decodeSgf('(;FF[4]SZ[9];B[];W[])') as SgfOk).state;
      expect(a.history.length, 2);
      expect(a.history.every((Move m) => m.isPass), isTrue);
      expect(a.ended, isTrue, reason: '두 번 패스면 끝난다');

      final GameState b = (decodeSgf('(;FF[4]SZ[19];B[tt])') as SgfOk).state;
      expect(b.history.single.isPass, isTrue);
    });

    test('SZ 가 없으면 19줄로 본다 (규격 기본값)', () {
      expect((decodeSgf('(;FF[4];B[aa])') as SgfOk).state.size, BoardSize.s19);
    });
  });

  group('replayTo', () {
    test('임의 지점으로 되돌린다', () {
      final GameState g = _randomGame(3, BoardSize.s9, 40);
      for (int ply = 0; ply <= g.history.length; ply++) {
        final GameState back = replayTo(g.size, g.history, ply);
        expect(back.history.length, ply);
      }
    });

    test('범위를 벗어난 값은 잘라낸다', () {
      final GameState g = _randomGame(4, BoardSize.s9, 20);
      expect(replayTo(g.size, g.history, -5).history, isEmpty);
      expect(replayTo(g.size, g.history, 9999).history.length, g.history.length);
    });

    test('끝까지 되돌리면 원본과 같은 판이다', () {
      final GameState g = _randomGame(5, BoardSize.s13, 45);
      final GameState back = replayTo(g.size, g.history, g.history.length);
      expect(back.board, g.board);
      expect(back.zobrist, g.zobrist);
      expect(back.blackCaptures, g.blackCaptures);
    });
  });
}
