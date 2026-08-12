// spikes/board_a11y/lib/coord.dart — 좌표·명령어 파서 (순수 로직)
//
// 격자 시맨틱스를 못 쓰는 대신 이게 시각장애 사용자의 1급 입력 경로가 된다.
// React 쪽 geometry.ts 의 columnLabel / rowLabel 규칙을 그대로 따른다:
// 열은 I 를 건너뛰고, 행은 아래가 1이다.

const String columnLetters = 'ABCDEFGHJKLMNOPQRST';

String columnLabel(int x) => x >= 0 && x < columnLetters.length ? columnLetters[x] : '?';

int rowLabel(int y, int size) => size - y;

String pointLabel(int x, int y, int size) => '${columnLabel(x)}${rowLabel(y, size)}';

/// 파서 결과
sealed class ParsedInput {
  const ParsedInput();
}

final class ParsedPoint extends ParsedInput {
  const ParsedPoint(this.x, this.y);
  final int x;
  final int y;
}

/// 착수 이외의 명령
enum Command { pass, resign, undo, score, hint, help, repeat, summary }

final class ParsedCommand extends ParsedInput {
  const ParsedCommand(this.command);
  final Command command;
}

/// 특정 지점·줄에 대한 질의
final class ParsedQuery extends ParsedInput {
  const ParsedQuery.point(this.x, this.y) : row = null;
  const ParsedQuery.row(this.row) : x = null, y = null;
  final int? x;
  final int? y;
  final int? row;
}

enum ParseErrorKind { empty, skippedLetter, badColumn, badRow, outOfRange, unknown }

final class ParsedError extends ParsedInput {
  const ParsedError(this.kind, this.detail);
  final ParseErrorKind kind;
  final String detail;
}

const Map<String, Command> _commandAliases = <String, Command>{
  // ko
  '패스': Command.pass,
  '기권': Command.resign,
  '무르기': Command.undo,
  '계가': Command.score,
  '힌트': Command.hint,
  '도움말': Command.help,
  '다시': Command.repeat,
  // en
  'pass': Command.pass,
  'resign': Command.resign,
  'undo': Command.undo,
  'score': Command.score,
  'hint': Command.hint,
  'help': Command.help,
  'r': Command.repeat,
  // ja / zh / vi (스파이크에서는 대표형만)
  'パス': Command.pass,
  '投了': Command.resign,
  '停着': Command.pass,
  '认输': Command.resign,
  'bỏlượt': Command.pass,
  'xinthua': Command.resign,
};

/// 입력 한 줄을 해석한다. size 는 판 줄 수.
ParsedInput parseInput(String raw, int size) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return const ParsedError(ParseErrorKind.empty, '');

  // 질의: ? / ?D16 / ?16
  if (trimmed.startsWith('?')) {
    final String rest = trimmed.substring(1).trim();
    if (rest.isEmpty) return const ParsedCommand(Command.summary);
    final ParsedInput asPoint = _parsePoint(rest, size);
    if (asPoint is ParsedPoint) return ParsedQuery.point(asPoint.x, asPoint.y);
    final int? row = int.tryParse(rest);
    if (row != null) {
      if (row < 1 || row > size) {
        return ParsedError(ParseErrorKind.outOfRange, '$row');
      }
      return ParsedQuery.row(row);
    }
    return asPoint is ParsedError ? asPoint : const ParsedError(ParseErrorKind.unknown, '');
  }

  final String key = trimmed.toLowerCase().replaceAll(' ', '');
  final Command? cmd = _commandAliases[key] ?? _commandAliases[trimmed];
  if (cmd != null) return ParsedCommand(cmd);

  return _parsePoint(trimmed, size);
}

/// "D16", "d 16", "4-16" 을 좌표로
ParsedInput _parsePoint(String raw, int size) {
  final String s = raw.toUpperCase().replaceAll(' ', '');

  // 숫자-숫자 형태: 열번호-행번호 (1부터)
  final RegExpMatch? numeric = RegExp(r'^(\d{1,2})[-,](\d{1,2})$').firstMatch(s);
  if (numeric != null) {
    final int col = int.parse(numeric.group(1)!);
    final int row = int.parse(numeric.group(2)!);
    if (col < 1 || col > size) return ParsedError(ParseErrorKind.outOfRange, '$col');
    if (row < 1 || row > size) return ParsedError(ParseErrorKind.outOfRange, '$row');
    return ParsedPoint(col - 1, size - row);
  }

  final RegExpMatch? m = RegExp(r'^([A-Z])(\d{1,2})$').firstMatch(s);
  if (m == null) return ParsedError(ParseErrorKind.unknown, raw.trim());

  final String letter = m.group(1)!;
  if (letter == 'I') return const ParsedError(ParseErrorKind.skippedLetter, 'I');

  final int x = columnLetters.indexOf(letter);
  if (x < 0 || x >= size) return ParsedError(ParseErrorKind.badColumn, letter);

  final int row = int.parse(m.group(2)!);
  if (row < 1 || row > size) return ParsedError(ParseErrorKind.badRow, '$row');

  return ParsedPoint(x, size - row);
}

/// 오류를 사람이 듣는 문장으로
String describeError(ParsedError e, int size) {
  switch (e.kind) {
    case ParseErrorKind.empty:
      return '입력이 비어 있습니다';
    case ParseErrorKind.skippedLetter:
      return 'I 는 쓰지 않습니다. H 다음은 J 입니다';
    case ParseErrorKind.badColumn:
      return '${e.detail} 열은 이 판에 없습니다. A 부터 ${columnLabel(size - 1)} 까지입니다';
    case ParseErrorKind.badRow:
    case ParseErrorKind.outOfRange:
      return '${e.detail} 은 범위 밖입니다. 1 부터 $size 까지입니다';
    case ParseErrorKind.unknown:
      return '${e.detail} 을 알 수 없습니다. 예: D16, 패스, 물음표';
  }
}
