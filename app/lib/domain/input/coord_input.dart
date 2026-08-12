// lib/domain/input/coord_input.dart — 좌표·명령어 입력 해석 (순수 Dart)
//
// Flutter 에는 격자 시맨틱스가 없어(SemanticsRole 에 grid/gridcell 자체가 없고
// Windows 는 MSAA 라 행·열을 전달할 통로가 없다) 스크린리더가 판을 "탐색"할 수 없다.
// 그래서 좌표를 말로 입력하는 경로가 보조가 아니라 **동등한 1급 입력**이다.
//
// 5개 언어의 명령어를 모두 받는다 — 한국어 사용자가 한글로 '패스'라고 칠 수 있어야 한다.

import '../engine/types.dart';

sealed class CoordInput {
  const CoordInput();
}

/// 착수 지점
final class CoordPoint extends CoordInput {
  const CoordPoint(this.x, this.y);
  final int x;
  final int y;
}

enum BoardCommand { pass, resign, undo, score, hint, help, repeat, summary }

final class CoordCommand extends CoordInput {
  const CoordCommand(this.command);
  final BoardCommand command;
}

/// 판을 읽어 달라는 질의
final class CoordQuery extends CoordInput {
  const CoordQuery.point(int this.x, int this.y) : row = null;
  const CoordQuery.row(int this.row) : x = null, y = null;
  final int? x;
  final int? y;
  final int? row;
}

enum CoordErrorKind { empty, skippedLetter, badColumn, badRow, unknown }

final class CoordError extends CoordInput {
  const CoordError(this.kind, this.detail);
  final CoordErrorKind kind;
  final String detail;
}

const String columnLetters = 'ABCDEFGHJKLMNOPQRST';

String columnLabel(int x) =>
    x >= 0 && x < columnLetters.length ? columnLetters[x] : '?';

/// board 배열은 y=0 이 위쪽, 표준 표기는 아래가 1
int rowLabel(int y, int lines) => lines - y;

/// 5개 언어 명령어. 공백을 제거하고 소문자로 맞춘 뒤 조회한다.
const Map<String, BoardCommand> _aliases = <String, BoardCommand>{
  // ko
  '패스': BoardCommand.pass,
  '기권': BoardCommand.resign,
  '무르기': BoardCommand.undo,
  '계가': BoardCommand.score,
  '힌트': BoardCommand.hint,
  '도움말': BoardCommand.help,
  '다시': BoardCommand.repeat,
  // en
  'pass': BoardCommand.pass,
  'resign': BoardCommand.resign,
  'undo': BoardCommand.undo,
  'score': BoardCommand.score,
  'hint': BoardCommand.hint,
  'help': BoardCommand.help,
  'r': BoardCommand.repeat,
  'again': BoardCommand.repeat,
  // ja
  'パス': BoardCommand.pass,
  '投了': BoardCommand.resign,
  '待った': BoardCommand.undo,
  '計算': BoardCommand.score,
  'ヒント': BoardCommand.hint,
  'ヘルプ': BoardCommand.help,
  // zh
  '停着': BoardCommand.pass,
  '认输': BoardCommand.resign,
  '悔棋': BoardCommand.undo,
  '数子': BoardCommand.score,
  '提示': BoardCommand.hint,
  '帮助': BoardCommand.help,
  // vi
  'bỏlượt': BoardCommand.pass,
  'xinthua': BoardCommand.resign,
  'hoàntác': BoardCommand.undo,
  'tínhđiểm': BoardCommand.score,
  'gợiý': BoardCommand.hint,
  'trợgiúp': BoardCommand.help,
};

/// 입력 한 줄을 해석한다
CoordInput parseCoordInput(String raw, BoardSize size) {
  final int lines = size.lines;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return const CoordError(CoordErrorKind.empty, '');

  // 질의: ? / ?D16 / ?16
  if (trimmed.startsWith('?')) {
    final String rest = trimmed.substring(1).trim();
    if (rest.isEmpty) return const CoordCommand(BoardCommand.summary);
    final CoordInput asPoint = _parsePoint(rest, lines);
    if (asPoint is CoordPoint) return CoordQuery.point(asPoint.x, asPoint.y);
    final int? row = int.tryParse(rest);
    if (row != null) {
      if (row < 1 || row > lines) {
        return CoordError(CoordErrorKind.badRow, '$row');
      }
      return CoordQuery.row(row);
    }
    return asPoint;
  }

  final String key = trimmed.toLowerCase().replaceAll(' ', '');
  final BoardCommand? cmd = _aliases[key] ?? _aliases[trimmed];
  if (cmd != null) return CoordCommand(cmd);

  return _parsePoint(trimmed, lines);
}

/// "D16", "d 16", "4-16" 을 좌표로
CoordInput _parsePoint(String raw, int lines) {
  final String s = raw.toUpperCase().replaceAll(' ', '');

  // 열번호-행번호 (둘 다 1부터) — 문자 열 이름을 모르는 사용자를 위해
  final RegExpMatch? numeric = RegExp(r'^(\d{1,2})[-,](\d{1,2})$').firstMatch(s);
  if (numeric != null) {
    final int col = int.parse(numeric.group(1)!);
    final int row = int.parse(numeric.group(2)!);
    if (col < 1 || col > lines) return CoordError(CoordErrorKind.badColumn, '$col');
    if (row < 1 || row > lines) return CoordError(CoordErrorKind.badRow, '$row');
    return CoordPoint(col - 1, lines - row);
  }

  final RegExpMatch? m = RegExp(r'^([A-Z])(\d{1,2})$').firstMatch(s);
  if (m == null) return CoordError(CoordErrorKind.unknown, raw.trim());

  final String letter = m.group(1)!;
  if (letter == 'I') return const CoordError(CoordErrorKind.skippedLetter, 'I');

  final int x = columnLetters.indexOf(letter);
  if (x < 0 || x >= lines) return CoordError(CoordErrorKind.badColumn, letter);

  final int row = int.parse(m.group(2)!);
  if (row < 1 || row > lines) return CoordError(CoordErrorKind.badRow, '$row');

  return CoordPoint(x, lines - row);
}
