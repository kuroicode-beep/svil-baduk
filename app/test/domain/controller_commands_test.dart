// test/domain/controller_commands_test.dart
//
// 좌표 명령어로 계가·힌트·무르기가 실제로 동작하는지. 체크리스트 A13 은
// 이 명령들이 "낭독된다" 를 요구하므로, 빈 문자열을 돌려주면 실패다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/game_controller.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/scoring.dart';
import 'package:svil_baduk/domain/engine/sgf.dart';
import 'package:svil_baduk/domain/engine/snapshot.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/input/coord_input.dart';

import '../support/speech_fixture.dart';

GameController _make([BoardSize size = BoardSize.s9]) => GameController(
      size: size,
      speech: testSpeech,
      moveErrorPhrase: (MoveError e) => e.name,
      coordErrorPhrase: (CoordError e, int lines) => e.runtimeType.toString(),
    );

String _spoken(PlayOutcome o) => switch (o) {
      PlayedMove(:final String speech) => speech,
      RejectedMove(:final String speech) => speech,
      SpokeOnly(:final String speech) => speech,
      GameEnded(:final String speech) => speech,
    };

void main() {
  group('명령어가 실제로 말한다 (A13)', () {
    test('계가 · 힌트 · 무르기가 빈 문자열을 돌려주지 않는다', () {
      final GameController c = _make();
      c.submitInput('D4');
      for (final String cmd in <String>['계가', '힌트', '무르기']) {
        expect(_spoken(c.submitInput(cmd)), isNotEmpty, reason: cmd);
      }
    });

    test('화면이 따로 처리할 명령은 도움말뿐이다', () {
      for (final BoardCommand cmd in BoardCommand.values) {
        expect(GameController.needsScreen(cmd), cmd == BoardCommand.help,
            reason: cmd.name);
      }
    });
  });

  group('계가', () {
    test('결과에 "추정" 이 들어간다 — 사석을 못 가리기 때문', () {
      expect(_spoken(_make().submitInput('계가')), contains('추정'));
    });

    test('룰을 바꾸면 결과가 따라 바뀐다', () {
      final GameController c = _make();
      final ScoreBreakdown jp = c.currentScore();
      c.rules = GoRules.chinese;
      expect(c.currentScore().komi, isNot(jp.komi));
    });

    test('덤을 직접 지정할 수 있다', () {
      final GameController c = _make()..komiOverride = 0;
      expect(c.currentScore().komi, 0);
    });
  });

  group('힌트', () {
    test('추천 수로 커서를 옮긴다 — 듣고 바로 엔터를 칠 수 있게', () {
      final GameController c = _make();
      c.setCursor(const Point(0, 0));
      c.submitInput('힌트');
      final Point best = c.topMoves().first.point;
      expect(c.cursorLabel, pointLabel(best.x, best.y, c.lines));
    });

    test('낭독에 좌표가 들어간다', () {
      final GameController c = _make();
      final String said = _spoken(c.submitInput('힌트'));
      expect(said, contains(pointLabel(c.topMoves().first.point.x,
          c.topMoves().first.point.y, c.lines)));
    });
  });

  group('무르기', () {
    test('한 수 되돌리고 무엇을 물렀는지 말한다', () {
      final GameController c = _make();
      c.submitInput('D4');
      expect(c.state.history.length, 1);
      final String said = _spoken(c.submitInput('무르기'));
      expect(c.state.history, isEmpty);
      expect(said, contains('D4'));
    });

    test('두 수 무르기 (AI 대국용)', () {
      final GameController c = _make();
      c.submitInput('D4');
      c.submitInput('E5');
      c.undo(plies: 2);
      expect(c.state.history, isEmpty);
      expect(c.state.toPlay, Stone.black);
    });

    test('무를 것이 없으면 그렇게 말한다 (침묵 금지)', () {
      final GameController c = _make();
      expect(c.canUndo, isFalse);
      expect(_spoken(c.submitInput('무르기')), testSpeech.noLastMoveWord);
    });

    test('무르면 따냄과 패 금지점도 되돌아간다', () {
      final GameController c = _make();
      for (final String m in <String>['B9', 'A9', 'A8', 'J1']) {
        c.submitInput(m);
      }
      expect(c.state.blackCaptures, 1);
      c.undo(plies: 2);
      expect(c.state.blackCaptures, 0);
      expect(c.state.koPoint, isNull);
    });

    test('무르기 뒤에도 커서가 판 안에 있다', () {
      final GameController c = _make();
      c.submitInput('D4');
      c.undo();
      expect(c.cursorLabel, isNotEmpty);
    });
  });

  group('저장·복원', () {
    test('스냅샷 왕복으로 판이 그대로 돌아온다', () {
      final GameController a = _make();
      for (final String m in <String>['D4', 'Q16', 'D16']) {
        a.submitInput(m);
      }
      final GameController b = _make();
      expect(b.loadSnapshot(a.saveSnapshot()), isA<SnapshotOk>());
      expect(b.state.board, a.state.board);
      expect(b.state.zobrist, a.state.zobrist);
    });

    test('손상된 스냅샷은 현재 대국을 건드리지 않는다', () {
      final GameController c = _make();
      c.submitInput('D4');
      final int before = c.state.zobrist;
      expect(c.loadSnapshot('{{{'), isA<SnapshotFail>());
      expect(c.state.zobrist, before, reason: '실패한 복원이 판을 바꿨습니다');
      expect(c.state.history.length, 1);
    });

    test('SGF 왕복', () {
      final GameController a = _make(BoardSize.s19);
      for (final String m in <String>['D4', 'Q16']) {
        a.submitInput(m);
      }
      final GameController b = _make();
      expect(b.loadSgf(a.toSgf(black: '인블루')), isA<SgfOk>());
      expect(b.state.board, a.state.board);
      expect(b.lines, 19, reason: '판 크기가 SGF 를 따라가야 한다');
    });

    test('깨진 SGF 도 현재 대국을 건드리지 않는다', () {
      final GameController c = _make();
      c.submitInput('D4');
      expect(c.loadSgf('그냥 텍스트'), isA<SgfFail>());
      expect(c.state.history.length, 1);
    });

    test('SGF 로 판이 커져도 커서가 범위를 벗어나지 않는다', () {
      final GameController big = _make(BoardSize.s19);
      big.submitInput('T19');
      final GameController small = _make(BoardSize.s9);
      small.setCursor(const Point(8, 8));
      // 19줄 → 9줄로 줄어드는 방향
      expect(big.loadSgf(small.toSgf()), isA<SgfOk>());
      expect(big.cursorLabel, isNotEmpty);
    });
  });
}
