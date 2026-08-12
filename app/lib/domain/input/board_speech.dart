// lib/domain/input/board_speech.dart — 낭독 문장 생성 (순수 Dart)
//
// 규칙: **좌표를 항상 문장 맨 앞에** 둔다.
// 스크린리더 발화가 중간에 끊기는 일이 잦은데(특히 커서를 빠르게 옮길 때),
// 위치만은 반드시 전달되어야 하기 때문이다.

import '../engine/board.dart';
import '../engine/types.dart';

/// 낭독 상세도 — UI 의 AnnounceVerbosity 와 짝을 이룬다
enum SpeechDetail { terse, full }

class BoardSpeech {
  const BoardSpeech({
    required this.blackWord,
    required this.whiteWord,
    required this.emptyWord,
    required this.starWord,
    required this.lastMoveWord,
    required this.libertyWord,
    required this.turnSuffix,
    required this.captureWord,
    required this.stoneCountWord,
    required this.noStonesWord,
    required this.rowWord,
    required this.noLastMoveWord,
    required this.passWord,
  });

  final String blackWord;
  final String whiteWord;
  final String emptyWord;
  final String starWord;
  final String lastMoveWord;
  final String libertyWord;
  final String turnSuffix;
  final String captureWord;
  final String stoneCountWord;
  final String noStonesWord;
  final String rowWord;
  final String noLastMoveWord;

  /// 패스는 좌표가 없다 (x=-1) — 좌표를 만들려 하면 터진다
  final String passWord;

  String _who(Stone s) => switch (s) {
        Stone.black => blackWord,
        Stone.white => whiteWord,
        Stone.empty => emptyWord,
      };

  /// 커서가 놓인 지점 — 가장 자주 발화되는 문장
  String point(
    GameState g,
    int x,
    int y, {
    SpeechDetail detail = SpeechDetail.terse,
    Point? lastMove,
  }) {
    final List<String> parts = <String>[
      pointLabel(x, y, g.lines),
      _who(g.stoneAt(x, y)),
    ];
    final bool isStar = starPoints(g.size).any((Point p) => p.x == x && p.y == y);
    if (isStar) parts.add(starWord);
    if (lastMove != null && lastMove.x == x && lastMove.y == y) {
      parts.add(lastMoveWord);
    }
    if (detail == SpeechDetail.full) {
      final Stone here = g.stoneAt(x, y);
      if (here != Stone.empty) {
        // 활로 수는 시각장애 사용자에게 실질적인 판단 재료다
        parts.add('$libertyWord ${_liberties(g, x, y)}');
      } else {
        final String around = _neighbours(g, x, y);
        if (around.isNotEmpty) parts.add(around);
      }
    }
    return parts.join(', ');
  }

  int _liberties(GameState g, int x, int y) {
    final Stone color = g.stoneAt(x, y);
    if (color == Stone.empty) return 0;
    final Set<int> seen = <int>{};
    final Set<int> libs = <int>{};
    final List<int> stack = <int>[y * g.lines + x];
    while (stack.isNotEmpty) {
      final int i = stack.removeLast();
      if (!seen.add(i)) continue;
      final int cx = i % g.lines;
      final int cy = i ~/ g.lines;
      for (final (int nx, int ny) in _adj(cx, cy, g.lines)) {
        final Stone s = g.stoneAt(nx, ny);
        if (s == Stone.empty) {
          libs.add(ny * g.lines + nx);
        } else if (s == color) {
          stack.add(ny * g.lines + nx);
        }
      }
    }
    return libs.length;
  }

  String _neighbours(GameState g, int x, int y) {
    final List<String> out = <String>[];
    const List<String> dirNames = <String>['위', '아래', '왼쪽', '오른쪽'];
    final List<(int, int)> dirs = <(int, int)>[
      (x, y - 1),
      (x, y + 1),
      (x - 1, y),
      (x + 1, y),
    ];
    for (int i = 0; i < dirs.length; i++) {
      final (int nx, int ny) = dirs[i];
      if (nx < 0 || ny < 0 || nx >= g.lines || ny >= g.lines) continue;
      final Stone s = g.stoneAt(nx, ny);
      if (s != Stone.empty) out.add('${dirNames[i]} ${_who(s)}');
    }
    return out.join(' ');
  }

  Iterable<(int, int)> _adj(int x, int y, int lines) sync* {
    if (x > 0) yield (x - 1, y);
    if (x < lines - 1) yield (x + 1, y);
    if (y > 0) yield (x, y - 1);
    if (y < lines - 1) yield (x, y + 1);
  }

  /// 착수 결과 — 좌표·따냄·다음 차례
  String moveResult(GameState after, Move move) {
    final List<String> parts = <String>[
      move.isPass
          ? '${_who(move.player)} $passWord'
          : '${_who(move.player)} ${pointLabel(move.x, move.y, after.lines)}',
    ];
    if (move.captured.isNotEmpty) {
      parts.add('${_who(move.player.opponent)} ${move.captured.length}$captureWord');
    }
    parts.add('${_who(after.toPlay)}$turnSuffix');
    return parts.join(', ');
  }

  /// 한 줄에 있는 돌 — "?16"
  String row(GameState g, int rowNumber) {
    final int y = g.lines - rowNumber;
    final List<String> parts = <String>[];
    for (int x = 0; x < g.lines; x++) {
      final Stone s = g.stoneAt(x, y);
      if (s != Stone.empty) parts.add('${columnLetters[x]} ${_who(s)}');
    }
    if (parts.isEmpty) return '$rowNumber$rowWord, $noStonesWord';
    return '$rowNumber$rowWord, ${parts.join(', ')}';
  }

  /// 판 전체 요약 — "?"
  String summary(GameState g, {Point? lastMove}) {
    int black = 0;
    int white = 0;
    for (int i = 0; i < g.board.length; i++) {
      if (g.board[i] == Stone.black.wire) black++;
      if (g.board[i] == Stone.white.wire) white++;
    }
    final String last = lastMove == null
        ? noLastMoveWord
        : '$lastMoveWord ${pointLabel(lastMove.x, lastMove.y, g.lines)}';
    return '${g.lines}$rowWord 판, '
        '$blackWord $black$stoneCountWord, '
        '$whiteWord $white$stoneCountWord, '
        '$last, '
        '${_who(g.toPlay)}$turnSuffix';
  }
}

const String columnLetters = 'ABCDEFGHJKLMNOPQRST';
