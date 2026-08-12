// test/domain/learn_controller_test.dart — 체크리스트 L1·L2·L6
//
// 실제 curriculum.json 으로 돈다. 문제 데이터가 깨지면 여기서 걸린다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/application/learn_controller.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/learn/curriculum.dart';

void main() {
  late Curriculum curriculum;

  setUpAll(() {
    curriculum =
        Curriculum.parse(File('assets/learn/curriculum.json').readAsStringSync());
  });

  LearnController make({Set<String> solved = const <String>{}}) =>
      LearnController(curriculum: curriculum, solved: solved);

  group('L1 · 교육 과정이 실린다', () {
    test('9스테이지 28문제', () {
      expect(curriculum.stages.length, 9);
      expect(curriculum.problemCount, 28);
    });

    test('트랙마다 스테이지가 있다', () {
      for (final LearnTrack t in LearnTrack.values) {
        expect(curriculum.forTrack(t), isNotEmpty, reason: t.name);
      }
    });
  });

  group('L2 · 정답이 실제로 통한다', () {
    test('모든 문제의 첫 정답이 받아들여진다', () {
      for (final LearnStage s in curriculum.stages) {
        for (int i = 0; i < s.problems.length; i++) {
          final LearnController c = make()..openStage(s);
          c.goTo(i);
          final Point sol = c.problem!.solutions.first;
          final AttemptOutcome r = c.attempt(sol.x, sol.y);
          final String why = r is AttemptWrong
              ? '${r.reasonKey} ${r.detail ?? ''}'
              : '';
          expect(r, isA<AttemptCorrect>(),
              reason: '${s.id} / ${c.problem!.id} $why');
        }
      }
    });

    test('엉뚱한 자리는 사유를 구별해 거절한다', () {
      final LearnController c = make()..openStage(curriculum.stages.first);
      // 정답도 돌도 아닌 자리를 찾는다
      final LearnProblem p = c.problem!;
      Point? empty;
      for (int y = 0; y < p.size.lines && empty == null; y++) {
        for (int x = 0; x < p.size.lines; x++) {
          final bool isSol = p.solutions.any((Point s) => s.x == x && s.y == y);
          final bool hasStone = p.black.any((Point s) => s.x == x && s.y == y) ||
              p.white.any((Point s) => s.x == x && s.y == y);
          if (!isSol && !hasStone) {
            empty = Point(x, y);
            break;
          }
        }
      }
      final AttemptOutcome r = c.attempt(empty!.x, empty.y);
      expect(r, isA<AttemptWrong>());
      expect((r as AttemptWrong).reasonKey, 'learnWrongPoint');
    });

    test('돌이 있는 자리도 사유를 붙여 거절한다 — 침묵 금지', () {
      // 배치된 돌이 있는 문제를 찾는다. 첫 스테이지는 빈 판에서 시작한다.
      LearnStage? withStones;
      int index = 0;
      for (final LearnStage s in curriculum.stages) {
        for (int i = 0; i < s.problems.length; i++) {
          if (s.problems[i].black.isNotEmpty || s.problems[i].white.isNotEmpty) {
            withStones = s;
            index = i;
            break;
          }
        }
        if (withStones != null) break;
      }
      expect(withStones, isNotNull, reason: '배치된 돌이 있는 문제가 없습니다');

      final LearnController c = make()..openStage(withStones!);
      c.goTo(index);
      final LearnProblem p = c.problem!;
      final Point occupied =
          p.black.isNotEmpty ? p.black.first : p.white.first;
      final AttemptOutcome r = c.attempt(occupied.x, occupied.y);
      expect(r, isA<AttemptWrong>());
      // 정답 좌표가 아니면 wrongPoint 가 먼저 잡히는 게 맞다.
      // 중요한 건 사유가 붙는다는 점이다.
      expect((r as AttemptWrong).reasonKey, isNotEmpty);
    });
  });

  group('진행 · 잠금', () {
    test('트랙의 첫 스테이지는 항상 열려 있다', () {
      final LearnController c = make();
      for (final LearnTrack t in LearnTrack.values) {
        expect(c.isUnlocked(curriculum.forTrack(t).first), isTrue,
            reason: t.name);
      }
    });

    test('앞 스테이지를 끝내야 다음이 열린다', () {
      final List<LearnStage> track = curriculum.forTrack(LearnTrack.basics);
      expect(track.length, greaterThan(1), reason: '잠금을 볼 스테이지가 없습니다');

      final LearnController c = make();
      expect(c.isUnlocked(track[1]), isFalse);

      final LearnController done = make(
        solved: track.first.problems.map((LearnProblem p) => p.id).toSet(),
      );
      expect(done.isUnlocked(track[1]), isTrue);
    });

    test('L6 · 저장된 진행을 이어받아 못 푼 문제부터 연다', () {
      final LearnStage s = curriculum.stages.first;
      expect(s.problems.length, greaterThan(1));
      final LearnController c = make(solved: <String>{s.problems.first.id})
        ..openStage(s);
      expect(c.position, 2, reason: '이미 푼 문제를 다시 보여줍니다');
    });

    test('다 푼 스테이지를 다시 열면 처음부터', () {
      final LearnStage s = curriculum.stages.first;
      final LearnController c = make(
        solved: s.problems.map((LearnProblem p) => p.id).toSet(),
      )..openStage(s);
      expect(c.position, 1);
      expect(c.stageCleared(s), isTrue);
    });

    test('스테이지를 끝내면 알려준다', () {
      final LearnStage s = curriculum.stages.first;
      final LearnController c = make(
        solved: s.problems.skip(1).map((LearnProblem p) => p.id).toSet(),
      )..openStage(s);
      final Point sol = c.problem!.solutions.first;
      final AttemptOutcome r = c.attempt(sol.x, sol.y);
      expect((r as AttemptCorrect).stageCleared, isTrue);
    });
  });

  group('판 다루기', () {
    test('다시 놓기가 원래 배치로 돌린다', () {
      final LearnController c = make()..openStage(curriculum.stages.first);
      final Point sol = c.problem!.solutions.first;
      c.attempt(sol.x, sol.y);
      final int afterMove = c.board!.history.length;
      c.retry();
      expect(afterMove, greaterThan(0));
      expect(c.board!.history, isEmpty);
    });

    test('문제를 옮기면 판도 새로 깔린다', () {
      final LearnController c = make()..openStage(curriculum.stages.first);
      final String first = c.problem!.id;
      c.next();
      expect(c.problem!.id, isNot(first));
      expect(c.board!.history, isEmpty);
    });

    test('범위를 벗어난 이동은 잘라낸다', () {
      final LearnController c = make()..openStage(curriculum.stages.first);
      c.goTo(-5);
      expect(c.position, 1);
      c.goTo(999);
      expect(c.position, c.total);
      expect(c.hasNext, isFalse);
    });

    test('두 번 틀리면 화면이 힌트를 권할 수 있게 센다', () {
      final LearnController c = make()..openStage(curriculum.stages.first);
      expect(c.misses, 0);
      c.attempt(0, 0);
      c.attempt(0, 0);
      expect(c.misses, greaterThanOrEqualTo(1));
      c.retry();
      expect(c.misses, 0, reason: '다시 놓기가 실패 횟수를 지우지 않았습니다');
    });
  });
}
