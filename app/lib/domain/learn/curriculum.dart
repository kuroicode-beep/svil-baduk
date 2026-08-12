// lib/domain/learn/curriculum.dart — 배우기 문제 데이터 모델 (순수 Dart)
//
// 데이터는 assets/learn/curriculum.json 에서 온다.
// (React 판 curriculum.ts 를 scripts/export_curriculum.mjs 가 변환)
// 손으로 옮기지 않으므로 양쪽 내용이 갈라질 수 없다.

import 'dart:convert';

import '../engine/board.dart';
import '../engine/types.dart';

enum LearnTrack { basics, fuseki, tsumego }

/// capture=따냄, place=정답 지점 착수, kill=상대 사, live=살림
enum ProblemGoal { capture, place, kill, live }

/// 언어별 문자열 — ko 는 반드시 있다
class LearnText {
  const LearnText(this._values);
  final Map<String, String> _values;

  String call(String langCode) =>
      _values[langCode] ?? _values['en'] ?? _values['ko']!;

  String get ko => _values['ko']!;

  static LearnText fromJson(Map<String, dynamic> j) =>
      LearnText(j.map((String k, dynamic v) => MapEntry<String, String>(k, v as String)));
}

class LearnProblem {
  const LearnProblem({
    required this.id,
    required this.title,
    required this.goalLabel,
    required this.goal,
    required this.size,
    required this.toPlay,
    required this.black,
    required this.white,
    required this.solutions,
    required this.hint,
    this.note,
  });

  final String id;
  final LearnText title;
  final LearnText goalLabel;
  final ProblemGoal goal;
  final BoardSize size;
  final Player toPlay;
  final List<Point> black;
  final List<Point> white;
  final List<Point> solutions;
  final LearnText hint;
  final LearnText? note;

  /// 문제의 시작 위치를 만든다
  GameState createState() => createProblemState(
        size: size,
        black: black,
        white: white,
        toPlay: toPlay,
      );

  static Point _pt(dynamic v) {
    final List<dynamic> p = v as List<dynamic>;
    return Point(p[0] as int, p[1] as int);
  }

  static LearnProblem fromJson(Map<String, dynamic> j) => LearnProblem(
        id: j['id'] as String,
        title: LearnText.fromJson(j['title'] as Map<String, dynamic>),
        goalLabel: LearnText.fromJson(j['goalLabel'] as Map<String, dynamic>),
        goal: ProblemGoal.values.byName(j['goal'] as String),
        size: BoardSize.fromLines(j['size'] as int),
        toPlay: Stone.fromWire(j['toPlay'] as int),
        black: (j['black'] as List<dynamic>).map(_pt).toList(),
        white: (j['white'] as List<dynamic>).map(_pt).toList(),
        solutions: (j['solutions'] as List<dynamic>).map(_pt).toList(),
        hint: LearnText.fromJson(j['hint'] as Map<String, dynamic>),
        note: j['note'] == null
            ? null
            : LearnText.fromJson(j['note'] as Map<String, dynamic>),
      );
}

class LearnStage {
  const LearnStage({
    required this.id,
    required this.track,
    required this.order,
    required this.title,
    required this.blurb,
    required this.refs,
    required this.problems,
  });

  final String id;
  final LearnTrack track;
  final int order;
  final LearnText title;
  final LearnText blurb;
  final LearnText refs;
  final List<LearnProblem> problems;

  static LearnStage fromJson(Map<String, dynamic> j) => LearnStage(
        id: j['id'] as String,
        track: LearnTrack.values.byName(j['track'] as String),
        order: j['order'] as int,
        title: LearnText.fromJson(j['title'] as Map<String, dynamic>),
        blurb: LearnText.fromJson(j['blurb'] as Map<String, dynamic>),
        refs: LearnText.fromJson(j['refs'] as Map<String, dynamic>),
        problems: (j['problems'] as List<dynamic>)
            .map((dynamic p) => LearnProblem.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class Curriculum {
  const Curriculum(this.stages);
  final List<LearnStage> stages;

  List<LearnStage> forTrack(LearnTrack t) =>
      stages.where((LearnStage s) => s.track == t).toList()
        ..sort((LearnStage a, LearnStage b) => a.order.compareTo(b.order));

  LearnStage? byId(String id) {
    for (final LearnStage s in stages) {
      if (s.id == id) return s;
    }
    return null;
  }

  int get problemCount =>
      stages.fold(0, (int n, LearnStage s) => n + s.problems.length);

  static Curriculum parse(String jsonText) {
    final Map<String, dynamic> j = jsonDecode(jsonText) as Map<String, dynamic>;
    return Curriculum(
      (j['stages'] as List<dynamic>)
          .map((dynamic s) => LearnStage.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 문제 풀이 판정.
///
/// React 판은 좌표 화이트리스트만 봤고, kill/live 목표는 규칙 엔진으로
/// 확인조차 하지 않았다. 여기서는 최소한 goal 이 실제로 달성됐는지 본다.
sealed class SolveResult {
  const SolveResult();
}

final class SolveCorrect extends SolveResult {
  const SolveCorrect(this.after);
  final GameState after;
}

final class SolveWrongPoint extends SolveResult {
  const SolveWrongPoint();
}

final class SolveIllegal extends SolveResult {
  const SolveIllegal(this.error);
  final MoveError error;
}

/// 정답 지점이지만 목표를 달성하지 못한 경우 (예: 따냄 문제인데 따내지 못함)
final class SolveGoalUnmet extends SolveResult {
  const SolveGoalUnmet();
}

SolveResult evaluateProblem(LearnProblem p, GameState board, int x, int y) {
  final bool isSolution =
      p.solutions.any((Point s) => s.x == x && s.y == y);
  if (!isSolution) return const SolveWrongPoint();

  final PlayResult r = tryPlay(board, x, y);
  if (r is PlayErr) return SolveIllegal(r.error);
  final PlayOk ok = r as PlayOk;

  if (p.goal == ProblemGoal.capture && ok.move.captured.isEmpty) {
    return const SolveGoalUnmet();
  }
  return SolveCorrect(ok.state);
}
