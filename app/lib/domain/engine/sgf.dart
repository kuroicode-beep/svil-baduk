// lib/domain/engine/sgf.dart — SGF FF[4] 읽기·쓰기 (수순만)
//
// 변화도·AB/AW 배치·주석은 1.0 범위 밖이다. 읽을 때 만나면 조용히
// 버리지 않고 이유를 붙여 거절한다 — 반쯤 읽힌 기보가 더 나쁘다.
//
// TS 판(src/sgf/sgf.ts)에서 고친 것:
//   좌표 정규식에 대소문자 무시 플래그가 있어 대문자 좌표가 통과했고,
//   그 뒤 파싱에 실패하면 null 이 되어 "패스" 로 처리됐다. 깨진 파일이
//   패스만 가득한 대국으로 조용히 바뀌던 경로다.

import '../../version.dart';
import 'board.dart';
import 'types.dart';

const String _letters = 'abcdefghijklmnopqrstuvwxyz';

String _sgfCoord(int x, int y) => '${_letters[x]}${_letters[y]}';

/// SGF 좌표 하나. 빈 값은 패스, 해석 불가는 null.
Point? _parseCoord(String s) {
  final int x = _letters.indexOf(s[0]);
  final int y = _letters.indexOf(s[1]);
  if (x < 0 || y < 0) return null;
  return Point(x, y);
}

/// 기보를 SGF 로 쓴다. 좌표계는 SGF 규격대로 좌상단이 원점이다
/// (화면 좌표계와 같고, 사람이 읽는 D16 표기와는 다르다).
String encodeSgf(GameState state, {String? black, String? white}) {
  final StringBuffer b = StringBuffer('(;FF[4]GM[1]');
  b.write('SZ[${state.size.lines}]');
  b.write('AP[SVIL-Baduk:$appVersion]');
  if (black != null && black.isNotEmpty) b.write('PB[${_escape(black)}]');
  if (white != null && white.isNotEmpty) b.write('PW[${_escape(white)}]');

  for (final Move m in state.history) {
    final String color = m.player == Stone.black ? 'B' : 'W';
    b.write(m.isPass ? ';$color[]' : ';$color[${_sgfCoord(m.x, m.y)}]');
  }
  b.write(')');
  return b.toString();
}

String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll(']', r'\]');

enum SgfError {
  notSgf,
  unsupportedSize,
  turnMismatch,
  badCoord,
  illegalMove,
}

sealed class SgfResult {
  const SgfResult();
}

final class SgfOk extends SgfResult {
  const SgfOk(this.state);
  final GameState state;
}

final class SgfFail extends SgfResult {
  const SgfFail(this.error, {this.detail});
  final SgfError error;

  /// 몇 수째에서 왜 막혔는지 — 화면·낭독에 그대로 쓴다
  final String? detail;
}

/// 소문자 좌표만 받는다. 대문자는 26줄 초과 판용이라 여기서는 오류다.
final RegExp _moveRe = RegExp(r';([BW])\[([a-z]{0,2})\]');

/// 수처럼 생긴 것 전부. 엄격한 정규식이 몇 개를 흘렸는지 세는 용도다 —
/// 안 맞는 토큰을 그냥 건너뛰면 깨진 파일이 "빈 대국" 으로 통과한다.
final RegExp _looseMoveRe = RegExp(r';[BWbw]\[[^\]]*\]');
final RegExp _sizeRe = RegExp(r'SZ\[(\d+)\]', caseSensitive: false);

SgfResult decodeSgf(String text) {
  final String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (!cleaned.contains('(')) return const SgfFail(SgfError.notSgf);

  final Match? sz = _sizeRe.firstMatch(cleaned);
  final int lines = sz == null ? 19 : int.parse(sz.group(1)!);
  if (lines != 9 && lines != 13 && lines != 19) {
    return SgfFail(SgfError.unsupportedSize, detail: '$lines');
  }

  final int strict = _moveRe.allMatches(cleaned).length;
  final int loose = _looseMoveRe.allMatches(cleaned).length;
  if (strict != loose) {
    // 대문자 좌표·세 글자 좌표 등. 어느 것이 문제인지 짚어준다.
    final String? bad = _looseMoveRe
        .allMatches(cleaned)
        .map((Match m) => m.group(0)!)
        .where((String t) => !_moveRe.hasMatch(t))
        .firstOrNull;
    return SgfFail(SgfError.badCoord, detail: bad ?? '${loose - strict}개');
  }

  GameState state = createGame(BoardSize.fromLines(lines));
  int ply = 0;

  for (final Match m in _moveRe.allMatches(cleaned)) {
    ply++;
    final String color = m.group(1)!;
    final String raw = m.group(2)!;

    final String expected = state.toPlay == Stone.black ? 'B' : 'W';
    if (color != expected) {
      return SgfFail(SgfError.turnMismatch, detail: '$ply수째 $color');
    }

    // 빈 값과 'tt'(옛 패스 표기)만 패스다. 그 밖의 해석 실패는 오류다.
    if (raw.isEmpty || raw == 'tt') {
      state = (passMove(state) as PlayOk).state;
      continue;
    }
    if (raw.length != 2) {
      return SgfFail(SgfError.badCoord, detail: '$ply수째 "$raw"');
    }
    final Point? p = _parseCoord(raw);
    if (p == null || !inBounds(lines, p.x, p.y)) {
      return SgfFail(SgfError.badCoord, detail: '$ply수째 "$raw"');
    }

    final PlayResult r = tryPlay(state, p.x, p.y);
    if (r is! PlayOk) {
      return SgfFail(SgfError.illegalMove,
          detail: '$ply수째 ${pointLabel(p.x, p.y, lines)}');
    }
    state = r.state;
  }

  return SgfOk(state);
}

/// 기보를 [ply] 수까지 되돌린 상태. 무르기·기보 탐색이 쓴다.
///
/// TS 판은 재생 중 실패하면 조용히 멈춘 상태를 돌려줬다. 여기서는
/// 재생이 끊기면 던진다 — 우리가 만든 기보가 다시 못 읽히면 그건 결함이다.
GameState replayTo(BoardSize size, List<Move> history, int ply) {
  final int n = ply.clamp(0, history.length);
  return replayHistory(size, history.sublist(0, n));
}
