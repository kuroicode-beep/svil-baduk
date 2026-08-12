// test/domain/curriculum_test.dart — 체크리스트 L1~L4
//
// React 판은 문제 데이터를 기계 검증할 수 없었고, 그래서 실제로 풀 수 없는
// 문제가 배포된 적이 있다. 여기서는 모든 문제를 규칙 엔진으로 재생해 본다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/learn/curriculum.dart';

void main() {
  late Curriculum curriculum;

  setUpAll(() {
    final File f = File('assets/learn/curriculum.json');
    expect(f.existsSync(), isTrue,
        reason: 'npm run curriculum:export 를 먼저 돌리세요');
    curriculum = Curriculum.parse(f.readAsStringSync());
  });

  test('L1 · 9스테이지 28문제가 로드된다', () {
    expect(curriculum.stages.length, 9);
    expect(curriculum.problemCount, 28);
  });

  test('트랙이 3개이고 순서가 1,2,3 이다', () {
    for (final LearnTrack t in LearnTrack.values) {
      final List<LearnStage> s = curriculum.forTrack(t);
      expect(s.length, 3, reason: '${t.name} 트랙');
      expect(s.map((LearnStage e) => e.order), <int>[1, 2, 3],
          reason: '${t.name} 트랙 순서');
    }
  });

  test('L3 · id 가 유일하다', () {
    final Set<String> ids = <String>{};
    for (final LearnStage s in curriculum.stages) {
      expect(ids.add(s.id), isTrue, reason: '스테이지 id 중복: ${s.id}');
      for (final LearnProblem p in s.problems) {
        expect(ids.add(p.id), isTrue, reason: '문제 id 중복: ${p.id}');
      }
    }
  });

  test('L4 · 모든 문자열에 ko 가 있다', () {
    for (final LearnStage s in curriculum.stages) {
      expect(s.title.ko, isNotEmpty);
      expect(s.blurb.ko, isNotEmpty);
      for (final LearnProblem p in s.problems) {
        expect(p.title.ko, isNotEmpty, reason: p.id);
        expect(p.goalLabel.ko, isNotEmpty, reason: p.id);
        expect(p.hint.ko, isNotEmpty, reason: p.id);
      }
    }
  });

  test('L3 · 배치 좌표가 판 안에 있고 겹치지 않는다', () {
    for (final LearnStage s in curriculum.stages) {
      for (final LearnProblem p in s.problems) {
        final Set<String> used = <String>{};
        for (final Point pt in <Point>[...p.black, ...p.white]) {
          expect(pt.x >= 0 && pt.x < p.size.lines, isTrue, reason: '${p.id} $pt');
          expect(pt.y >= 0 && pt.y < p.size.lines, isTrue, reason: '${p.id} $pt');
          expect(used.add('${pt.x},${pt.y}'), isTrue,
              reason: '${p.id}: 같은 자리에 돌이 둘 (${pt.x},${pt.y})');
        }
      }
    }
  });

  test('L2 · 모든 정답이 빈 자리이고 합법 착수다', () {
    final List<String> bad = <String>[];
    for (final LearnStage s in curriculum.stages) {
      for (final LearnProblem p in s.problems) {
        final GameState start = p.createState();
        for (final Point sol in p.solutions) {
          if (start.stoneAt(sol.x, sol.y) != Stone.empty) {
            bad.add('${p.id}: 정답 자리에 이미 돌이 있음 $sol');
            continue;
          }
          final PlayResult r = tryPlay(start, sol.x, sol.y);
          if (r is PlayErr) {
            bad.add('${p.id}: 정답이 반칙 $sol — ${r.error.name}');
          }
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('L2 · 따냄 문제는 정답을 두면 실제로 따낸다', () {
    // 목표가 데이터에 적혀만 있고 실제로는 달성되지 않는 문제를 잡는다
    final List<String> bad = <String>[];
    for (final LearnStage s in curriculum.stages) {
      for (final LearnProblem p in s.problems) {
        if (p.goal != ProblemGoal.capture) continue;
        for (final Point sol in p.solutions) {
          final SolveResult r =
              evaluateProblem(p, p.createState(), sol.x, sol.y);
          if (r is! SolveCorrect) {
            bad.add('${p.id}: 정답 $sol 을 둬도 따내지 못함 (${r.runtimeType})');
          }
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('배치는 차례를 바꾸지 않고 따냄도 일으키지 않는다', () {
    for (final LearnStage s in curriculum.stages) {
      for (final LearnProblem p in s.problems) {
        final GameState g = p.createState();
        expect(g.toPlay, p.toPlay, reason: p.id);
        expect(g.history, isEmpty, reason: p.id);
        expect(g.blackCaptures, 0, reason: p.id);
        // 배치된 돌이 그대로 있어야 한다 (설치이지 착수가 아니다)
        for (final Point pt in p.black) {
          expect(g.stoneAt(pt.x, pt.y), Stone.black, reason: '${p.id} $pt');
        }
        for (final Point pt in p.white) {
          expect(g.stoneAt(pt.x, pt.y), Stone.white, reason: '${p.id} $pt');
        }
      }
    }
  });

  test('오답·반칙을 구분해 돌려준다', () {
    final LearnProblem p = curriculum.stages.first.problems.first;
    final GameState start = p.createState();
    // 정답이 아닌 빈 자리
    final Point sol = p.solutions.first;
    final int otherX = (sol.x + 1) % p.size.lines;
    final SolveResult wrong = evaluateProblem(p, start, otherX, sol.y);
    expect(wrong, isA<SolveWrongPoint>());
  });
}
