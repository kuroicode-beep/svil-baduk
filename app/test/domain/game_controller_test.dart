// test/domain/game_controller_test.dart — 체크리스트 A6·A8·A11·A12·A13
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/game_controller.dart';
import 'package:svil_baduk/domain/engine/types.dart';

import '../support/speech_fixture.dart';
import 'package:svil_baduk/domain/input/coord_input.dart';


String moveErr(MoveError e) => switch (e) {
      MoveError.occupied => '둘 수 없음: 이미 돌이 있습니다',
      MoveError.ko => '둘 수 없음: 패입니다',
      MoveError.superko => '둘 수 없음: 같은 판이 반복됩니다',
      MoveError.suicide => '둘 수 없음: 자살수입니다',
      MoveError.gameEnded => '대국이 끝났습니다',
      MoveError.outOfBounds => '판 밖입니다',
    };

String coordErr(CoordError e, int lines) => switch (e.kind) {
      CoordErrorKind.skippedLetter => 'I 는 쓰지 않습니다',
      CoordErrorKind.badColumn => '${e.detail} 열은 없습니다',
      CoordErrorKind.badRow => '${e.detail} 은 범위 밖입니다',
      CoordErrorKind.empty => '입력이 비어 있습니다',
      CoordErrorKind.unknown => '${e.detail} 을 알 수 없습니다',
    };

GameController make([BoardSize size = BoardSize.s19]) => GameController(
      size: size,
      speech: testSpeech,
      moveErrorPhrase: moveErr,
      coordErrorPhrase: coordErr,
    );

void main() {
  group('커서', () {
    test('가운데에서 시작한다', () {
      final GameController c = make();
      expect(c.cursor, const Point(9, 9));
      expect(c.cursorLabel, 'K10');
    });

    test('기하학적으로 한 칸씩 — 합법 지점으로 점프하지 않는다', () {
      final GameController c = make();
      c.moveCursor(1, 0);
      expect(c.cursor, const Point(10, 9));
      c.moveCursor(0, -1);
      expect(c.cursor, const Point(10, 8));
    });

    test('가장자리에서 멈춘다 — 반대편으로 순간이동하지 않는다', () {
      final GameController c = make(BoardSize.s9);
      c.setCursor(const Point(0, 0));
      c.moveCursor(-1, -1);
      expect(c.cursor, const Point(0, 0));
      c.setCursor(const Point(8, 8));
      c.moveCursor(1, 1);
      expect(c.cursor, const Point(8, 8));
    });

    test('커서 문장이 항상 좌표로 시작한다', () {
      final GameController c = make();
      c.setCursor(const Point(3, 3));
      expect(c.cursorSpeech.startsWith('D16'), isTrue);
    });
  });

  group('A8 · 반칙은 사유별로 다른 문장을 낸다 (침묵 금지)', () {
    test('이미 돌이 있는 자리', () {
      final GameController c = make();
      c.place(3, 3);
      final PlayOutcome r = c.place(3, 3);
      expect(r, isA<RejectedMove>());
      final RejectedMove rm = r as RejectedMove;
      expect(rm.error, MoveError.occupied);
      // 좌표가 먼저, 그다음 사유
      expect(rm.speech.startsWith('D16'), isTrue);
      expect(rm.speech, contains('이미 돌이 있습니다'));
    });

    test('사유가 서로 다른 문장이다', () {
      final Set<String> phrases =
          MoveError.values.map(moveErr).toSet();
      expect(phrases.length, MoveError.values.length,
          reason: '사유마다 구별되는 문장이어야 합니다');
    });
  });

  group('A6 · 착수 결과 낭독', () {
    test('색·좌표·차례를 말한다', () {
      final GameController c = make();
      final PlayOutcome r = c.place(3, 3);
      expect((r as PlayedMove).speech, '흑 D16, 백 차례');
    });

    test('따냄을 포함한다', () {
      final GameController c = make(BoardSize.s9);
      c.place(1, 0); // 흑
      c.place(0, 0); // 백
      final PlayOutcome r = c.place(0, 1); // 흑이 따냄
      expect((r as PlayedMove).speech, contains('백 1점 따냄'));
    });
  });

  group('좌표 입력 처리', () {
    test('좌표를 입력하면 커서가 옮겨지고 착수된다', () {
      final GameController c = make();
      final PlayOutcome r = c.submitInput('D16');
      expect(r, isA<PlayedMove>());
      expect(c.cursor, const Point(3, 3));
      expect(c.state.stoneAt(3, 3), Stone.black);
    });

    test('A12 · 실패해도 상태가 망가지지 않는다', () {
      final GameController c = make();
      c.submitInput('D16');
      final int before = c.state.history.length;
      final PlayOutcome r = c.submitInput('D16'); // 같은 자리
      expect(r, isA<RejectedMove>());
      expect(c.state.history.length, before);
    });

    test('잘못된 입력은 InputError — 낭독하되 실패로 구분된다', () {
      // SpokeOnly 로 돌려주면 화면이 성공으로 보고 입력을 비운다(A12 위반,
      // 실측로 발견). 오류는 타입으로 구분해야 좌표칸이 텍스트를 남긴다.
      final GameController c = make();
      for (final String bad in <String>['I5', 'Z99', '무슨소리', '']) {
        final PlayOutcome r = c.submitInput(bad);
        expect(r, isA<InputError>(), reason: bad);
        expect((r as InputError).speech, isNotEmpty, reason: bad);
      }
      expect(c.state.history, isEmpty);
    });

    test('패스 명령이 5개 언어로 동작한다', () {
      for (final String s in <String>['pass', '패스', 'パス', '停着']) {
        final GameController c = make();
        final PlayOutcome r = c.submitInput(s);
        expect(r, isA<PlayedMove>(), reason: s);
        expect(c.state.history.single.isPass, isTrue, reason: s);
      }
    });

    test('기권 명령이 대국을 끝낸다', () {
      final GameController c = make();
      final PlayOutcome r = c.submitInput('기권');
      expect(r, isA<GameEnded>());
      expect(c.state.ended, isTrue);
    });

    test('A13 · 질의는 낭독만 한다', () {
      final GameController c = make();
      c.place(3, 3);
      final PlayOutcome summary = c.submitInput('?');
      expect(summary, isA<SpokeOnly>());
      expect((summary as SpokeOnly).speech, contains('흑 1점'));

      final PlayOutcome pointQ = c.submitInput('?D16');
      expect((pointQ as SpokeOnly).speech.startsWith('D16'), isTrue);

      final PlayOutcome rowQ = c.submitInput('?16');
      expect((rowQ as SpokeOnly).speech, contains('D 흑'));

      // 질의로 판이 바뀌지 않았다
      expect(c.state.history.length, 1);
    });

    test('r 은 마지막 안내를 반복한다', () {
      final GameController c = make();
      final PlayOutcome r = c.submitInput('r', lastSpoken: '방금 한 말');
      expect((r as SpokeOnly).speech, '방금 한 말');
    });
  });

  group('확정 모드', () {
    test('겨눔 → 착수', () {
      final GameController c = make();
      c.setCursor(const Point(3, 3));
      c.arm();
      expect(c.armed, isTrue);
      final PlayOutcome r = c.placeAtCursor();
      expect(r, isA<PlayedMove>());
      expect(c.armed, isFalse);
    });

    test('커서를 옮기면 겨눔이 풀린다 — 오착수 방지', () {
      final GameController c = make();
      c.arm();
      c.moveCursor(1, 0);
      expect(c.armed, isFalse);
    });
  });

  group('두 번 패스로 종국', () {
    test('종국을 알린다', () {
      final GameController c = make();
      c.pass();
      final PlayOutcome r = c.pass();
      expect(r, isA<GameEnded>());
      expect(c.state.ended, isTrue);
    });
  });
}
