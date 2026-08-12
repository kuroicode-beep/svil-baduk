// 좌표 파서 단위 테스트 — 스파이크의 유일한 자동 검증
import 'package:flutter_test/flutter_test.dart';
import 'package:board_a11y/coord.dart';

void main() {
  test('열은 I 를 건너뛴다', () {
    expect(columnLabel(7), 'H');
    expect(columnLabel(8), 'J');
  });

  test('행은 아래가 1 — 19줄 좌상 화점은 D16', () {
    expect(pointLabel(3, 3, 19), 'D16');
    expect(pointLabel(3, 15, 19), 'D4');
  });

  test('여러 표기를 같은 지점으로 읽는다', () {
    for (final String s in <String>['D16', 'd16', 'D 16', '4-16']) {
      final ParsedInput r = parseInput(s, 19);
      expect(r, isA<ParsedPoint>(), reason: s);
      expect((r as ParsedPoint).x, 3, reason: s);
      expect(r.y, 3, reason: s);
    }
  });

  test('I 와 범위 밖을 구별해 거부한다', () {
    expect((parseInput('I5', 19) as ParsedError).kind, ParseErrorKind.skippedLetter);
    expect((parseInput('D99', 19) as ParsedError).kind, ParseErrorKind.badRow);
    expect((parseInput('Z9', 19) as ParsedError).kind, ParseErrorKind.badColumn);
    expect((parseInput('무슨소리', 19) as ParsedError).kind, ParseErrorKind.unknown);
  });

  test('명령어를 5개 언어로 받는다', () {
    for (final String s in <String>['pass', '패스', 'パス', '停着']) {
      expect((parseInput(s, 19) as ParsedCommand).command, Command.pass, reason: s);
    }
    expect((parseInput('기권', 19) as ParsedCommand).command, Command.resign);
  });

  test('질의 문법', () {
    expect((parseInput('?', 19) as ParsedCommand).command, Command.summary);
    final ParsedQuery p = parseInput('?D16', 19) as ParsedQuery;
    expect(p.x, 3);
    expect(p.y, 3);
    expect((parseInput('?16', 19) as ParsedQuery).row, 16);
  });
}
