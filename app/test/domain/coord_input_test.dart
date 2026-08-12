// test/domain/coord_input_test.dart — 체크리스트 A9·A10·A13·A14
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/input/coord_input.dart';

void main() {
  group('A9 · 여러 표기를 같은 지점으로 읽는다', () {
    test('D16 / d16 / D 16 / 4-16 이 모두 같다', () {
      for (final String s in <String>['D16', 'd16', 'D 16', '4-16']) {
        final CoordInput r = parseCoordInput(s, BoardSize.s19);
        expect(r, isA<CoordPoint>(), reason: s);
        expect((r as CoordPoint).x, 3, reason: s);
        expect(r.y, 3, reason: s);
      }
    });

    test('파서와 엔진의 좌표 표기가 정확히 일치한다', () {
      // 눈에 보이는 좌표와 낭독되는 좌표가 갈라지면 안 된다
      for (final BoardSize size in BoardSize.values) {
        for (int y = 0; y < size.lines; y++) {
          for (int x = 0; x < size.lines; x++) {
            final String label = pointLabel(x, y, size.lines);
            expect('${columnLabel(x)}${rowLabel(y, size.lines)}', label);
            final CoordInput back = parseCoordInput(label, size);
            expect(back, isA<CoordPoint>(), reason: label);
            expect((back as CoordPoint).x, x, reason: label);
            expect(back.y, y, reason: label);
          }
        }
      }
    });
  });

  group('A10 · 오류를 구분해 알려준다', () {
    test('I 는 쓰지 않는다', () {
      final CoordInput r = parseCoordInput('I5', BoardSize.s19);
      expect((r as CoordError).kind, CoordErrorKind.skippedLetter);
    });

    test('범위 밖 행·열', () {
      expect((parseCoordInput('D99', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badRow);
      expect((parseCoordInput('Z5', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badColumn);
      // 9줄 판에서 K 는 범위 밖
      expect((parseCoordInput('K5', BoardSize.s9) as CoordError).kind,
          CoordErrorKind.badColumn);
      expect((parseCoordInput('D0', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badRow);
    });

    test('알 수 없는 입력과 빈 입력을 구분한다', () {
      expect((parseCoordInput('무슨소리', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.unknown);
      expect((parseCoordInput('   ', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.empty);
    });

    test('숫자 표기의 범위도 검사한다', () {
      expect((parseCoordInput('99-1', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badColumn);
      expect((parseCoordInput('1-99', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badRow);
    });
  });

  group('A14 · 명령어를 5개 언어로 받는다', () {
    test('패스', () {
      for (final String s in <String>['pass', '패스', 'パス', '停着', 'bỏ lượt']) {
        expect((parseCoordInput(s, BoardSize.s19) as CoordCommand).command,
            BoardCommand.pass,
            reason: s);
      }
    });

    test('기권', () {
      for (final String s in <String>['resign', '기권', '投了', '认输', 'xin thua']) {
        expect((parseCoordInput(s, BoardSize.s19) as CoordCommand).command,
            BoardCommand.resign,
            reason: s);
      }
    });

    test('무르기·계가·힌트', () {
      expect((parseCoordInput('무르기', BoardSize.s19) as CoordCommand).command,
          BoardCommand.undo);
      expect((parseCoordInput('계가', BoardSize.s19) as CoordCommand).command,
          BoardCommand.score);
      expect((parseCoordInput('힌트', BoardSize.s19) as CoordCommand).command,
          BoardCommand.hint);
      expect((parseCoordInput('hint', BoardSize.s19) as CoordCommand).command,
          BoardCommand.hint);
    });

    test('대소문자·공백을 견딘다', () {
      expect((parseCoordInput('  PASS  ', BoardSize.s19) as CoordCommand).command,
          BoardCommand.pass);
      expect((parseCoordInput('Resign', BoardSize.s19) as CoordCommand).command,
          BoardCommand.resign);
    });
  });

  group('A13 · 질의 문법', () {
    test('? 는 판 요약', () {
      expect((parseCoordInput('?', BoardSize.s19) as CoordCommand).command,
          BoardCommand.summary);
    });

    test('?D16 은 그 지점', () {
      final CoordQuery q = parseCoordInput('?D16', BoardSize.s19) as CoordQuery;
      expect(q.x, 3);
      expect(q.y, 3);
      expect(q.row, isNull);
    });

    test('?16 은 그 줄', () {
      final CoordQuery q = parseCoordInput('?16', BoardSize.s19) as CoordQuery;
      expect(q.row, 16);
      expect(q.x, isNull);
    });

    test('질의의 범위 오류도 잡는다', () {
      expect((parseCoordInput('?99', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.badRow);
      expect((parseCoordInput('?I5', BoardSize.s19) as CoordError).kind,
          CoordErrorKind.skippedLetter);
    });

    test('r 은 마지막 안내 반복', () {
      expect((parseCoordInput('r', BoardSize.s19) as CoordCommand).command,
          BoardCommand.repeat);
      expect((parseCoordInput('다시', BoardSize.s19) as CoordCommand).command,
          BoardCommand.repeat);
    });
  });
}
