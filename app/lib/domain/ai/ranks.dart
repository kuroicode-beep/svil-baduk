// lib/domain/ai/ranks.dart — 난이도 10단계
//
// KataGo 신경망은 visits=1 이어도 사람보다 강하다. 그래서 저레벨은
// 엔진을 아예 안 쓰고 내장 휴리스틱의 무작위 비율로만 약하게 만든다.

class RankOption {
  const RankOption({
    required this.id,
    required this.level,
    required this.visits,
    required this.maxTime,
    required this.randomness,
    required this.moveTemperature,
  });

  final String id;

  /// 1~10
  final int level;

  /// KataGo maxVisits (대략)
  final int visits;

  /// 한 수 상한 — GPU 에서도 체감되는 값이라 상한을 둔다
  final Duration maxTime;

  /// 합법 수 중 무작위로 고르는 비율 (1.0 = 완전 랜덤)
  final double randomness;

  /// KataGo 후보 선택 온도. 내장 AI 전용 레벨에서는 무시된다.
  final double moveTemperature;

  /// i18n 키 — 라벨을 코드에 박지 않는다 (하드코딩 문자열 0 규칙)
  String get labelKey => 'rank_$id';
}

const List<RankOption> kRanks = <RankOption>[
  RankOption(id: 'lv1', level: 1, visits: 1, maxTime: Duration(milliseconds: 100), randomness: 1.0, moveTemperature: 5),
  RankOption(id: 'lv2', level: 2, visits: 1, maxTime: Duration(milliseconds: 150), randomness: 0.97, moveTemperature: 4),
  RankOption(id: 'lv3', level: 3, visits: 2, maxTime: Duration(milliseconds: 250), randomness: 0.9, moveTemperature: 3),
  RankOption(id: 'lv4', level: 4, visits: 4, maxTime: Duration(milliseconds: 400), randomness: 0.8, moveTemperature: 2.2),
  RankOption(id: 'lv5', level: 5, visits: 12, maxTime: Duration(milliseconds: 700), randomness: 0.45, moveTemperature: 1.4),
  RankOption(id: 'lv6', level: 6, visits: 24, maxTime: Duration(milliseconds: 1000), randomness: 0.3, moveTemperature: 1.0),
  RankOption(id: 'lv7', level: 7, visits: 48, maxTime: Duration(milliseconds: 1300), randomness: 0.18, moveTemperature: 0.6),
  RankOption(id: 'lv8', level: 8, visits: 100, maxTime: Duration(milliseconds: 1800), randomness: 0.1, moveTemperature: 0.35),
  RankOption(id: 'lv9', level: 9, visits: 180, maxTime: Duration(milliseconds: 2400), randomness: 0.05, moveTemperature: 0.2),
  RankOption(id: 'lv10', level: 10, visits: 320, maxTime: Duration(milliseconds: 3200), randomness: 0.02, moveTemperature: 0.1),
];

const String kDefaultRank = 'lv3';

RankOption getRank(String id) =>
    kRanks.firstWhere((RankOption r) => r.id == id,
        orElse: () => kRanks[2]); // 못 찾으면 기본 난이도

/// 입문~초급+ 는 내장 AI 만 쓴다 — 신경망은 최저 설정에서도 너무 강하다
bool usesKataGoEngine(String id) => getRank(id).level >= 5;
