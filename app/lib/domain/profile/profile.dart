// lib/domain/profile/profile.dart — 플레이어 프로필 (순수 Dart)
//
// React 판 src/profile/{store,progress}.ts 이식. 저장 키와 필드 이름을
// 그대로 유지한다 — 백업 JSON(내보내기/가져오기)이 양쪽에서 호환돼야 한다.
//
// 급수(grade)는 저장하지 않고 bestAiLevel 에서 유도한다. 두 번째 진실
// 원천을 만들면 어긋난다. Stitch 기획의 "Rank: 1 Dan" 표기가 근거다.

import 'dart:convert';

import '../ai/ranks.dart';

/// React 판과 동일한 저장 키 (localStorage ↔ shared_preferences)
const String kProfileKey = 'svil-baduk-profile';

class Profile {
  const Profile({
    this.name = '',
    this.avatar = 'pine',
    this.createdAt,
    this.level = 1,
    this.xp = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.highScore = 0,
    this.bestAiLevel = 0,
    this.gamesPlayed = 0,
  });

  final String name;

  /// React 판의 AvatarId 문자열 그대로 (pine·crane·mountain·river·stone·lantern)
  final String avatar;
  final String? createdAt;
  final int level;
  final int xp;
  final int wins;
  final int losses;
  final int draws;

  /// 승리 시 내 총점 최고
  final int highScore;

  /// 이긴 상대 AI 난이도(1–10) 최고 — 급수 유도의 근거
  final int bestAiLevel;
  final int gamesPlayed;

  Profile copyWith({
    String? name,
    String? avatar,
    String? createdAt,
    int? level,
    int? xp,
    int? wins,
    int? losses,
    int? draws,
    int? highScore,
    int? bestAiLevel,
    int? gamesPlayed,
  }) =>
      Profile(
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt ?? this.createdAt,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        draws: draws ?? this.draws,
        highScore: highScore ?? this.highScore,
        bestAiLevel: bestAiLevel ?? this.bestAiLevel,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'avatar': avatar,
        'createdAt': createdAt,
        'level': level,
        'xp': xp,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'highScore': highScore,
        'bestAiLevel': bestAiLevel,
        'gamesPlayed': gamesPlayed,
      };
}

String encodeProfile(Profile p) => jsonEncode(p.toJson());

/// 손상·누락에 관대하게 읽는다 — 프로필이 날아가는 것보다 기본값이 낫다
Profile decodeProfile(String? raw) {
  if (raw == null || raw.isEmpty) return const Profile();
  try {
    final Object? j = jsonDecode(raw);
    if (j is! Map) return const Profile();
    int n(String k, int d) => j[k] is int ? j[k] as int : d;
    return Profile(
      name: j['name'] is String ? j['name'] as String : '',
      avatar: j['avatar'] is String ? j['avatar'] as String : 'pine',
      createdAt: j['createdAt'] is String ? j['createdAt'] as String : null,
      level: n('level', 1),
      xp: n('xp', 0),
      wins: n('wins', 0),
      losses: n('losses', 0),
      draws: n('draws', 0),
      highScore: n('highScore', 0),
      bestAiLevel: n('bestAiLevel', 0),
      gamesPlayed: n('gamesPlayed', 0),
    );
  } catch (_) {
    return const Profile();
  }
}

// ── 진행 규칙 (React progress.ts 그대로) ─────────────────────────

/// 다음 레벨까지 필요 XP
int xpToNextLevel(int level) => 40 + level * 30;

({Profile profile, int leveledUp}) applyXp(Profile p, int gained) {
  int level = p.level;
  int xp = p.xp + (gained > 0 ? gained : 0);
  int leveledUp = 0;
  int guard = 0;
  while (xp >= xpToNextLevel(level) && guard < 50) {
    xp -= xpToNextLevel(level);
    level += 1;
    leveledUp += 1;
    guard += 1;
  }
  return (profile: p.copyWith(level: level, xp: xp), leveledUp: leveledUp);
}

int xpForResult({required bool won, required bool draw, required String rankId}) {
  final int lv = getRank(rankId).level;
  if (draw) return 8 + lv;
  if (won) return 20 + lv * 8;
  return 5 + lv ~/ 2;
}

class GameRecordInput {
  const GameRecordInput({
    required this.myColorWire,
    required this.winnerWire,
    required this.myScore,
    required this.rankId,
  });

  /// 1=흑 2=백 (엔진 와이어 값)
  final int myColorWire;

  /// 0=무승부 1=흑 2=백
  final int winnerWire;
  final int myScore;
  final String rankId;
}

class GameRecordResult {
  const GameRecordResult({
    required this.profile,
    required this.leveledUp,
    required this.xpGained,
    required this.newHighScore,
    required this.newBestAi,
  });

  final Profile profile;
  final int leveledUp;
  final int xpGained;
  final bool newHighScore;
  final bool newBestAi;
}

GameRecordResult recordSoloResult(Profile profile, GameRecordInput input) {
  final bool won = input.winnerWire == input.myColorWire;
  final bool draw = input.winnerWire == 0;
  final int xpGained =
      xpForResult(won: won, draw: draw, rankId: input.rankId);
  final int aiLevel = getRank(input.rankId).level;

  Profile next = profile.copyWith(
    gamesPlayed: profile.gamesPlayed + 1,
    wins: profile.wins + (won ? 1 : 0),
    losses: profile.losses + (!won && !draw ? 1 : 0),
    draws: profile.draws + (draw ? 1 : 0),
  );

  bool newHighScore = false;
  if (won && input.myScore > next.highScore) {
    next = next.copyWith(highScore: input.myScore);
    newHighScore = true;
  }

  bool newBestAi = false;
  if (won && aiLevel > next.bestAiLevel) {
    next = next.copyWith(bestAiLevel: aiLevel);
    newBestAi = true;
  }

  final ({Profile profile, int leveledUp}) leveled = applyXp(next, xpGained);
  return GameRecordResult(
    profile: leveled.profile,
    leveledUp: leveled.leveledUp,
    xpGained: xpGained,
    newHighScore: newHighScore,
    newBestAi: newBestAi,
  );
}

// ── 급수 유도 ────────────────────────────────────────────────────

/// 이긴 최고 AI 난이도 → 급/단. 저장하지 않고 매번 유도한다.
///
/// | bestAiLevel | 급수 |
/// | 0 | 입문 | 1 | 18급 | 2 | 15급 | 3 | 12급 | 4 | 9급 | 5 | 7급 |
/// | 6 | 5급 | 7 | 3급 | 8 | 1급 | 9 | 초단 | 10 | 2단 |
sealed class Grade {
  const Grade();
}

final class GradeBeginner extends Grade {
  const GradeBeginner();
}

final class GradeKyu extends Grade {
  const GradeKyu(this.n);
  final int n;
}

final class GradeDan extends Grade {
  const GradeDan(this.n);
  final int n;
}

Grade gradeForBestAi(int bestAiLevel) => switch (bestAiLevel) {
      <= 0 => const GradeBeginner(),
      1 => const GradeKyu(18),
      2 => const GradeKyu(15),
      3 => const GradeKyu(12),
      4 => const GradeKyu(9),
      5 => const GradeKyu(7),
      6 => const GradeKyu(5),
      7 => const GradeKyu(3),
      8 => const GradeKyu(1),
      9 => const GradeDan(1),
      _ => const GradeDan(2),
    };
