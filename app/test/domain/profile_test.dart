// test/domain/profile_test.dart — 프로필·진행 규칙 (React progress.test 대응 + 급수)

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/profile/profile.dart';

void main() {
  group('저장 왕복', () {
    test('모든 필드가 그대로 돌아온다 — React 백업과 같은 키', () {
      const Profile p = Profile(
        name: '인블루',
        avatar: 'crane',
        createdAt: '2026-08-14T00:00:00Z',
        level: 4,
        xp: 55,
        wins: 7,
        losses: 2,
        draws: 1,
        highScore: 42,
        bestAiLevel: 5,
        gamesPlayed: 10,
      );
      final Profile back = decodeProfile(encodeProfile(p));
      expect(back.toJson(), p.toJson());
    });

    test('React 판이 저장한 JSON 을 그대로 읽는다', () {
      const String reactJson =
          '{"name":"돌이","avatar":"stone","createdAt":"2026-01-01",'
          '"level":3,"xp":10,"wins":5,"losses":2,"draws":0,'
          '"highScore":42,"bestAiLevel":3,"gamesPlayed":7}';
      final Profile p = decodeProfile(reactJson);
      expect(p.name, '돌이');
      expect(p.bestAiLevel, 3);
      expect(p.wins, 5);
    });

    test('손상·누락은 기본값 — 프로필이 날아가지 않는다', () {
      expect(decodeProfile(null).level, 1);
      expect(decodeProfile('{{{').name, '');
      expect(decodeProfile('{"name":"a"}').xp, 0, reason: '누락 필드는 기본값');
      expect(decodeProfile('{"level":"셋"}').level, 1, reason: '타입이 틀리면 기본값');
    });
  });

  group('XP 규칙 (React 와 동일해야 한다)', () {
    test('레벨별 필요 XP', () {
      expect(xpToNextLevel(1), 70);
      expect(xpToNextLevel(5), 190);
    });

    test('승리가 패배보다 크고, 난이도가 높을수록 크다', () {
      final int winLv5 = xpForResult(won: true, draw: false, rankId: 'lv5');
      final int loseLv5 = xpForResult(won: false, draw: false, rankId: 'lv5');
      final int winLv9 = xpForResult(won: true, draw: false, rankId: 'lv9');
      expect(winLv5, greaterThan(loseLv5));
      expect(winLv9, greaterThan(winLv5));
      // React 공식 그대로: 승 20+lv*8, 무 8+lv, 패 5+lv~/2
      expect(winLv5, 60);
      expect(loseLv5, 7);
      expect(xpForResult(won: false, draw: true, rankId: 'lv5'), 13);
    });

    test('레벨업이 연쇄로 일어난다', () {
      final ({Profile profile, int leveledUp}) r =
          applyXp(const Profile(), 200);
      // 70(1→2) + 100(2→3) = 170 소모, 30 잔여
      expect(r.profile.level, 3);
      expect(r.profile.xp, 30);
      expect(r.leveledUp, 2);
    });
  });

  group('대국 기록', () {
    test('승리 — 전적·최고점·최고 AI 가 함께 갱신된다', () {
      final GameRecordResult r = recordSoloResult(
        const Profile(),
        const GameRecordInput(
            myColorWire: 1, winnerWire: 1, myScore: 42, rankId: 'lv5'),
      );
      expect(r.profile.wins, 1);
      expect(r.profile.losses, 0);
      expect(r.profile.highScore, 42);
      expect(r.profile.bestAiLevel, 5);
      expect(r.newHighScore, isTrue);
      expect(r.newBestAi, isTrue);
      expect(r.xpGained, 60);
    });

    test('패배 — 최고 기록은 건드리지 않는다', () {
      final GameRecordResult r = recordSoloResult(
        const Profile(highScore: 50, bestAiLevel: 7),
        const GameRecordInput(
            myColorWire: 1, winnerWire: 2, myScore: 60, rankId: 'lv9'),
      );
      expect(r.profile.losses, 1);
      expect(r.profile.highScore, 50, reason: '진 판의 점수가 최고점이 되면 안 된다');
      expect(r.profile.bestAiLevel, 7);
    });

    test('무승부', () {
      final GameRecordResult r = recordSoloResult(
        const Profile(),
        const GameRecordInput(
            myColorWire: 1, winnerWire: 0, myScore: 0, rankId: 'lv3'),
      );
      expect(r.profile.draws, 1);
      expect(r.xpGained, 11);
    });
  });

  group('급수 유도 — 저장하지 않고 bestAiLevel 에서', () {
    test('전체 매핑', () {
      expect(gradeForBestAi(0), isA<GradeBeginner>());
      expect((gradeForBestAi(1) as GradeKyu).n, 18);
      expect((gradeForBestAi(4) as GradeKyu).n, 9);
      expect((gradeForBestAi(8) as GradeKyu).n, 1);
      expect((gradeForBestAi(9) as GradeDan).n, 1);
      expect((gradeForBestAi(10) as GradeDan).n, 2);
    });

    test('레벨이 오르면 급수가 내려가지 않는다 (급은 작을수록 세다)', () {
      int strength(Grade g) => switch (g) {
            GradeBeginner() => 0,
            GradeKyu(:final int n) => 100 - n,
            GradeDan(:final int n) => 100 + n,
          };
      for (int i = 1; i <= 10; i++) {
        expect(strength(gradeForBestAi(i)),
            greaterThan(strength(gradeForBestAi(i - 1))),
            reason: 'bestAiLevel $i');
      }
    });
  });
}
