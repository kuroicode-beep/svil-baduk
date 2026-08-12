// lib/application/learn_controller.dart — 배우기 진행 상태
//
// 문제 하나를 풀 때마다 상태가 바뀌므로 대국과 같은 ChangeNotifier 로 둔다.
// 낭독 문장은 여기서 만들지 않는다 — 화면이 i18n 을 붙인다.

import 'package:flutter/foundation.dart';

import '../domain/engine/board.dart';
import '../domain/engine/types.dart';
import '../domain/input/board_speech.dart';
import '../domain/learn/curriculum.dart';

/// 문제 하나의 시도 결과 — 화면이 무엇을 낭독할지 정하는 근거
sealed class AttemptOutcome {
  const AttemptOutcome();
}

final class AttemptCorrect extends AttemptOutcome {
  const AttemptCorrect({required this.stageCleared, required this.trackCleared});

  /// 이 문제로 스테이지가 끝났는가
  final bool stageCleared;
  final bool trackCleared;
}

final class AttemptWrong extends AttemptOutcome {
  const AttemptWrong(this.reasonKey, {this.detail});

  /// i18n 키 — 왜 틀렸는지 구별해서 말한다 (침묵·뭉뚱그리기 금지)
  final String reasonKey;
  final String? detail;
}

class LearnController extends ChangeNotifier {
  LearnController({
    required this.curriculum,
    required Set<String> solved,
    required this.speech,
    this.detail = SpeechDetail.terse,
  }) : _solved = Set<String>.from(solved);

  final Curriculum curriculum;
  final BoardSpeech speech;
  SpeechDetail detail;
  final Set<String> _solved;

  /// 대국 화면과 같은 커서 모델 — 판 조작 방식이 화면마다 다르면 안 된다
  Point _cursor = const Point(0, 0);
  Point get cursor => _cursor;

  int get lines => _board?.size.lines ?? 9;

  String get cursorLabel => pointLabel(_cursor.x, _cursor.y, lines);

  String get cursorSpeech {
    final GameState? b = _board;
    if (b == null) return '';
    return speech.point(b, _cursor.x, _cursor.y, detail: detail);
  }

  void moveCursor(int dx, int dy) {
    setCursor(Point(
      (_cursor.x + dx).clamp(0, lines - 1),
      (_cursor.y + dy).clamp(0, lines - 1),
    ));
  }

  void setCursor(Point p) {
    final Point next =
        Point(p.x.clamp(0, lines - 1), p.y.clamp(0, lines - 1));
    if (next.x == _cursor.x && next.y == _cursor.y) return;
    _cursor = next;
    notifyListeners();
  }

  /// 힌트를 이미 들었는가 — 화면이 정답 공개를 단계적으로 여는 근거
  bool _hintShown = false;
  bool get hintShown => _hintShown;

  void showHint() {
    _hintShown = true;
    notifyListeners();
  }

  /// 정답 자리로 커서를 옮긴다 (정답 보기)
  void revealAnswer() {
    final LearnProblem? p = problem;
    if (p == null || p.solutions.isEmpty) return;
    _hintShown = true;
    _cursor = p.solutions.first;
    notifyListeners();
  }

  AttemptOutcome attemptAtCursor() => attempt(_cursor.x, _cursor.y);

  LearnStage? _stage;
  int _index = 0;
  GameState? _board;

  /// 이번 문제에서 틀린 횟수 — 두 번 틀리면 화면이 힌트를 권한다
  int _misses = 0;

  Set<String> get solvedIds => Set<String>.unmodifiable(_solved);
  LearnStage? get stage => _stage;
  GameState? get board => _board;
  int get misses => _misses;

  LearnProblem? get problem {
    final LearnStage? s = _stage;
    if (s == null || _index >= s.problems.length) return null;
    return s.problems[_index];
  }

  /// "3 / 7" 처럼 보여줄 위치
  int get position => _index + 1;
  int get total => _stage?.problems.length ?? 0;

  bool isSolved(String problemId) => _solved.contains(problemId);

  bool stageCleared(LearnStage s) =>
      s.problems.every((LearnProblem p) => _solved.contains(p.id));

  bool trackCleared(LearnTrack t) =>
      curriculum.forTrack(t).every(stageCleared);

  /// 잠금 규칙: 트랙의 첫 스테이지는 항상 열려 있고,
  /// 나머지는 바로 앞 스테이지를 끝내야 열린다.
  bool isUnlocked(LearnStage s) {
    final List<LearnStage> track = curriculum.forTrack(s.track);
    final int i = track.indexWhere((LearnStage x) => x.id == s.id);
    if (i <= 0) return true;
    return stageCleared(track[i - 1]);
  }

  void openStage(LearnStage s) {
    _stage = s;
    // 아직 못 푼 첫 문제부터 — 다 풀었으면 처음부터 다시
    final int next =
        s.problems.indexWhere((LearnProblem p) => !_solved.contains(p.id));
    _index = next < 0 ? 0 : next;
    _resetBoard();
    notifyListeners();
  }

  /// 스테이지 목록으로 돌아간다
  void closeStage() {
    _stage = null;
    _board = null;
    notifyListeners();
  }

  void goTo(int index) {
    final LearnStage? s = _stage;
    if (s == null) return;
    _index = index.clamp(0, s.problems.length - 1);
    _resetBoard();
    notifyListeners();
  }

  bool get hasNext => _stage != null && _index < _stage!.problems.length - 1;
  bool get hasPrevious => _index > 0;

  void next() => goTo(_index + 1);
  void previous() => goTo(_index - 1);

  /// 판을 문제의 시작 배치로 되돌린다
  void retry() {
    _resetBoard();
    notifyListeners();
  }

  void _resetBoard() {
    final LearnProblem? p = problem;
    _misses = 0;
    _hintShown = false;
    _board = p == null
        ? null
        : createProblemState(
            size: p.size,
            black: p.black,
            white: p.white,
            toPlay: p.toPlay,
          );
    // 커서는 판 한가운데에서 시작한다 — 판이 바뀌면 범위를 벗어날 수 있다
    final int n = p?.size.lines ?? 9;
    _cursor = Point(n ~/ 2, n ~/ 2);
  }

  AttemptOutcome attempt(int x, int y) {
    final LearnProblem? p = problem;
    final GameState? b = _board;
    if (p == null || b == null) {
      return const AttemptWrong('learnNoProblem');
    }

    final SolveResult r = evaluateProblem(p, b, x, y);
    switch (r) {
      case SolveCorrect(:final GameState after):
        _board = after;
        _solved.add(p.id);
        final bool cleared = stageCleared(_stage!);
        notifyListeners();
        return AttemptCorrect(
          stageCleared: cleared,
          trackCleared: cleared && trackCleared(_stage!.track),
        );

      case SolveWrongPoint():
        _misses++;
        notifyListeners();
        return const AttemptWrong('learnWrongPoint');

      case SolveIllegal(:final MoveError error):
        _misses++;
        notifyListeners();
        // 반칙은 사유까지 말한다 — "틀렸습니다" 로 뭉뚱그리면 배울 수 없다
        return AttemptWrong('learnIllegal', detail: error.name);

      case SolveGoalUnmet():
        _misses++;
        notifyListeners();
        return const AttemptWrong('learnGoalUnmet');
    }
  }
}
