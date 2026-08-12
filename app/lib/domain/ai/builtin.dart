// lib/domain/ai/builtin.dart — KataGo 없이 두는 휴리스틱 AI
//
// TS 판(src/ai/builtin.ts)에서 두 가지를 고쳐 옮겼다.
//
// 1. scoreMove 와 scoreMoveDeterministic 이 흔들림 항 하나만 다른
//    복붙 쌍이었다. 한쪽만 고치면 힌트와 실제 착수가 갈라진다 → 한 함수로.
// 2. Math.random() 직접 호출이라 "1000판 반칙 0" 을 재현 가능하게
//    검증할 수 없었다 → Random 을 주입받는다.

import 'dart:math' as math;

import '../engine/board.dart';
import '../engine/types.dart';
import 'ranks.dart';

class RankedMove {
  const RankedMove({required this.point, required this.score, required this.rank, required this.percent});
  final Point point;
  final double score;

  /// 1부터 — 화면·낭독의 "1순위"
  final int rank;

  /// 최고 수 대비 백분율 (1~100)
  final int percent;
}

/// 한 수의 가치. [jitter] 가 0 이면 완전 결정적이다 (힌트·테스트용).
double _scoreMove(GameState state, Point p, double jitter, math.Random rng) {
  final PlayResult r = tryPlay(state, p.x, p.y);
  if (r is! PlayOk) return double.negativeInfinity;

  double score = r.move.captured.length * 50.0;

  // 중앙 선호 — 초심자에게 자연스러운 모양이 나온다
  final double center = (state.size.lines - 1) / 2;
  final double dist = (p.x - center).abs() + (p.y - center).abs();
  score += (state.size.lines - dist) * 0.5;

  // 1선은 약간 피한다
  final int last = state.size.lines - 1;
  if (p.x == 0 || p.y == 0 || p.x == last || p.y == last) score -= 2;

  // 상대에게 따냄 기회를 많이 주는 수는 감점.
  // capturePoints 가 전수 시뮬레이션과 같은 답을 O(판 크기) 로 준다.
  final GameState after = r.state;
  if (after.toPlay == state.toPlay.opponent) {
    if (capturePoints(after).length > 2) score -= 3;
  }

  return jitter == 0 ? score : score + rng.nextDouble() * jitter;
}

/// 내장 AI 의 한 수. 둘 곳이 없으면 null (호출자가 패스로 처리).
Point? pickBuiltinMove(GameState state, String rankId, {math.Random? rng}) {
  final math.Random r = rng ?? math.Random();
  final List<Point> moves = legalMoves(state);
  if (moves.isEmpty) return null;

  final RankOption rank = getRank(rankId);
  // 저레벨은 여기서 끝난다 — 탐색을 아예 안 하므로 19줄에서도 즉시 응답
  if (r.nextDouble() < rank.randomness) {
    return moves[r.nextInt(moves.length)];
  }

  Point best = moves.first;
  double bestScore = double.negativeInfinity;
  for (final Point m in moves) {
    final double s = _scoreMove(state, m, 2, r);
    if (s > bestScore) {
      bestScore = s;
      best = m;
    }
  }
  return best;
}

/// 힌트·분석용 상위 n수. 무작위 항이 없어 같은 판이면 항상 같은 답이 나온다.
List<RankedMove> pickBuiltinTopMoves(GameState state, {int n = 3}) {
  final List<Point> moves = legalMoves(state);
  if (moves.isEmpty) return const <RankedMove>[];

  final math.Random unused = math.Random(0); // jitter 0 이라 쓰이지 않는다
  final List<(Point, double)> scored = <(Point, double)>[];
  for (final Point p in moves) {
    final double s = _scoreMove(state, p, 0, unused);
    if (s.isFinite) scored.add((p, s));
  }
  if (scored.isEmpty) return const <RankedMove>[];

  scored.sort((( Point, double) a, (Point, double) b) => b.$2.compareTo(a.$2));
  final List<(Point, double)> top = scored.take(math.max(1, n)).toList();
  final double best = math.max(top.first.$2, 1);

  return <RankedMove>[
    for (int i = 0; i < top.length; i++)
      RankedMove(
        point: top[i].$1,
        score: top[i].$2,
        rank: i + 1,
        percent: math.max(1, (top[i].$2 / best * 100).round()),
      ),
  ];
}
