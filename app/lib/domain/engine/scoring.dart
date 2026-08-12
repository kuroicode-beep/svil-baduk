// lib/domain/engine/scoring.dart — 집 계산 (일본식·중국식)
//
// 사석을 판정하지 않는 근사치다. 두 번 패스로 끝난 판에서 죽은 돌이
// 판 위에 남아 있으면 그 돌은 살아 있는 것으로 세어진다.
// 정확한 계가는 사활 판정기가 필요하고 이 앱의 범위 밖이다.
// 화면에는 반드시 "추정"이라고 표시한다.

import 'types.dart';

int _idx(int lines, int x, int y) => y * lines + x;

enum GoRules {
  japanese('japanese'),
  chinese('chinese');

  const GoRules(this.wire);
  final String wire;

  static GoRules fromWire(String s) =>
      s == 'chinese' ? GoRules.chinese : GoRules.japanese;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.blackTerritory,
    required this.whiteTerritory,
    required this.blackCaptures,
    required this.whiteCaptures,
    required this.blackStones,
    required this.whiteStones,
    required this.komi,
    required this.rules,
    required this.blackTotal,
    required this.whiteTotal,
    required this.winner,
    required this.ownership,
  });

  final int blackTerritory;
  final int whiteTerritory;
  final int blackCaptures;
  final int whiteCaptures;
  final int blackStones;
  final int whiteStones;
  final double komi;
  final GoRules rules;
  final double blackTotal;
  final double whiteTotal;

  /// null = 무승부 (덤이 반집이라 실무상 거의 없다)
  final Player? winner;

  /// 빈 점 소유 — black=흑집, white=백집, empty=공배
  final List<Stone> ownership;

  /// 이긴 쪽이 몇 집 이겼는지 (양수)
  double get margin => (blackTotal - whiteTotal).abs();
}

/// 판 크기·룰별 표준 덤.
/// 중국룰은 크기와 무관하게 7.5 (계가법이 달라 값도 다르다).
double komiFor(BoardSize size, [GoRules rules = GoRules.japanese]) {
  if (rules == GoRules.chinese) return 7.5;
  return size == BoardSize.s19 ? 6.5 : 5.5;
}

ScoreBreakdown estimateScore(
  GameState state, {
  GoRules rules = GoRules.japanese,
  double? komiOverride,
}) {
  final int size = state.size.lines;
  final List<Stone> ownership =
      List<Stone>.filled(size * size, Stone.empty, growable: false);
  final Set<int> visited = <int>{};
  int blackTerritory = 0;
  int whiteTerritory = 0;
  int blackStones = 0;
  int whiteStones = 0;

  for (int i = 0; i < state.board.length; i++) {
    if (state.board[i] == Stone.black.wire) {
      blackStones++;
    } else if (state.board[i] == Stone.white.wire) {
      whiteStones++;
    }
  }

  // 빈 점을 연결 영역으로 묶고, 한 색에만 닿으면 그 색의 집
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final int start = _idx(size, x, y);
      if (state.board[start] != Stone.empty.wire || visited.contains(start)) {
        continue;
      }

      final List<int> region = <int>[];
      final List<Point> stack = <Point>[Point(x, y)];
      bool touchesBlack = false;
      bool touchesWhite = false;

      while (stack.isNotEmpty) {
        final Point p = stack.removeLast();
        final int pi = _idx(size, p.x, p.y);
        if (visited.contains(pi)) continue;
        if (state.board[pi] != Stone.empty.wire) continue;
        visited.add(pi);
        region.add(pi);

        for (final Point n in _neighbors(size, p.x, p.y)) {
          final int v = state.board[_idx(size, n.x, n.y)];
          if (v == Stone.black.wire) {
            touchesBlack = true;
          } else if (v == Stone.white.wire) {
            touchesWhite = true;
          } else if (!visited.contains(_idx(size, n.x, n.y))) {
            stack.add(n);
          }
        }
      }

      Stone owner = Stone.empty;
      if (touchesBlack && !touchesWhite) {
        owner = Stone.black;
      } else if (touchesWhite && !touchesBlack) {
        owner = Stone.white;
      }

      for (final int i in region) {
        ownership[i] = owner;
      }
      if (owner == Stone.black) {
        blackTerritory += region.length;
      } else if (owner == Stone.white) {
        whiteTerritory += region.length;
      }
    }
  }

  final double komi = komiOverride ?? komiFor(state.size, rules);
  final double blackTotal;
  final double whiteTotal;
  if (rules == GoRules.chinese) {
    // 영역법: 집 + 판 위의 돌
    blackTotal = (blackTerritory + blackStones).toDouble();
    whiteTotal = whiteTerritory + whiteStones + komi;
  } else {
    // 집계법: 집 + 잡은 돌
    blackTotal = (blackTerritory + state.blackCaptures).toDouble();
    whiteTotal = whiteTerritory + state.whiteCaptures + komi;
  }

  // 기권은 집 수를 무시하고 승자를 정한다
  Player? winner;
  if (state.resignedBy == Stone.black) {
    winner = Stone.white;
  } else if (state.resignedBy == Stone.white) {
    winner = Stone.black;
  } else if (blackTotal > whiteTotal) {
    winner = Stone.black;
  } else if (whiteTotal > blackTotal) {
    winner = Stone.white;
  }

  return ScoreBreakdown(
    blackTerritory: blackTerritory,
    whiteTerritory: whiteTerritory,
    blackCaptures: state.blackCaptures,
    whiteCaptures: state.whiteCaptures,
    blackStones: blackStones,
    whiteStones: whiteStones,
    komi: komi,
    rules: rules,
    blackTotal: blackTotal,
    whiteTotal: whiteTotal,
    winner: winner,
    ownership: ownership,
  );
}

List<Point> _neighbors(int size, int x, int y) => <Point>[
      if (x > 0) Point(x - 1, y),
      if (x < size - 1) Point(x + 1, y),
      if (y > 0) Point(x, y - 1),
      if (y < size - 1) Point(x, y + 1),
    ];
