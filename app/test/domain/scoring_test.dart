// test/domain/scoring_test.dart — 체크리스트 G5
//
// 기준 위치는 손으로 세어 검증할 수 있게 작게 잡았다.
// 사석 판정이 없다는 점을 마지막 테스트가 명시적으로 고정한다 —
// 이 근사가 조용히 "정확한 계가" 로 오해되지 않게.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/scoring.dart';
import 'package:svil_baduk/domain/engine/types.dart';

/// 문자 판에서 상태를 만든다 ('.'=빈 점, 'b'=흑, 'w'=백)
GameState _from(List<String> rows) {
  final int n = rows.length;
  // 9·13·19 만 존재한다. 3×3 을 넘기면 fromLines 가 조용히 기본값으로
  // 떨어져 좌표가 전부 어긋난다 — 여기서 잡는다.
  if (n != 9 && n != 13 && n != 19) {
    throw ArgumentError('판 크기는 9·13·19 만 됩니다 (받은 값 $n)');
  }
  final List<Point> black = <Point>[];
  final List<Point> white = <Point>[];
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      if (rows[y][x] == 'b') black.add(Point(x, y));
      if (rows[y][x] == 'w') white.add(Point(x, y));
    }
  }
  return createProblemState(
    size: BoardSize.fromLines(n),
    black: black,
    white: white,
    toPlay: Stone.black,
  );
}

void main() {
  group('덤', () {
    test('일본룰은 판 크기별, 중국룰은 고정 7.5', () {
      expect(komiFor(BoardSize.s19), 6.5);
      expect(komiFor(BoardSize.s13), 5.5);
      expect(komiFor(BoardSize.s9), 5.5);
      for (final BoardSize s in BoardSize.values) {
        expect(komiFor(s, GoRules.chinese), 7.5, reason: '${s.lines}줄');
      }
    });
  });

  group('G5 · 일본룰 기준 위치 5개', () {
    test('1 · 빈 판은 공배뿐이라 집이 0, 백이 덤으로 이긴다', () {
      final ScoreBreakdown s = estimateScore(createGame(BoardSize.s9));
      expect(s.blackTerritory, 0);
      expect(s.whiteTerritory, 0);
      expect(s.winner, Stone.white);
      expect(s.margin, 5.5);
    });

    test('2 · 백돌이 하나도 없으면 빈 점 전부가 흑집', () {
      // 흑 한 줄만 있는 판. 양쪽 영역 모두 흑에게만 닿는다.
      final GameState g = _from(<String>[
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
      ]);
      final ScoreBreakdown s = estimateScore(g);
      expect(s.blackTerritory, 72, reason: '81 - 흑돌 9 = 72, 오른쪽도 흑집이다');
      expect(s.whiteTerritory, 0);
    });

    test('2b · 백돌이 생기면 그 영역이 흑집에서 빠진다', () {
      final GameState g = _from(<String>[
        '..b....w.',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
        '..b......',
      ]);
      final ScoreBreakdown s = estimateScore(g);
      // 오른쪽 영역이 흑·백 양쪽에 닿아 통째로 공배가 된다
      expect(s.blackTerritory, 18, reason: '왼쪽 2열 × 9줄만 남는다');
      expect(s.whiteTerritory, 0);
    });

    test('3 · 양쪽에 닿는 영역은 공배 — 어느 쪽 집도 아니다', () {
      final GameState g = _from(<String>[
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
      ]);
      final ScoreBreakdown s = estimateScore(g);
      expect(s.blackTerritory, 0);
      expect(s.whiteTerritory, 0);
      // 가운데 열 9점이 전부 공배 — 어느 쪽 소유도 아니다
      expect(s.ownership.where((Stone o) => o != Stone.empty), isEmpty);
    });

    test('4 · 잡은 돌이 집계에 더해진다 (집계법)', () {
      GameState g = createGame(BoardSize.s9);
      // 백을 한 점 잡는다: 흑이 (0,0) 백돌을 둘러싼다
      for (final (int, int, Player) m in <(int, int, Player)>[
        (1, 0, Stone.black), (0, 0, Stone.white),
        (0, 1, Stone.black), (8, 8, Stone.white),
      ]) {
        final PlayResult r = tryPlay(g, m.$1, m.$2);
        g = (r as PlayOk).state;
      }
      expect(g.blackCaptures, 1, reason: '흑이 백 한 점을 잡았다');
      final ScoreBreakdown s = estimateScore(g);
      expect(s.blackCaptures, 1);
      expect(s.blackTotal, s.blackTerritory + 1);
    });

    test('5 · 기권은 집 수를 뒤집는다', () {
      final GameState g = resign(createGame(BoardSize.s9), Stone.white);
      final ScoreBreakdown s = estimateScore(g);
      // 백이 덤을 갖고도 기권했으므로 흑승
      expect(s.whiteTotal, greaterThan(s.blackTotal));
      expect(s.winner, Stone.black, reason: '기권은 계가보다 우선한다');
    });
  });

  group('G5 · 중국룰 기준 위치 5개', () {
    test('1 · 판 위의 돌이 점수에 들어간다', () {
      final GameState g = _from(<String>[
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
        'bbb.wwwww',
      ]);
      final ScoreBreakdown jp = estimateScore(g);
      final ScoreBreakdown cn = estimateScore(g, rules: GoRules.chinese);
      expect(cn.blackTotal - jp.blackTotal, 27, reason: '흑돌 3열 × 9줄');
      expect(cn.blackStones, 27);
      expect(cn.whiteStones, 45);
    });

    test('2 · 중국룰 덤은 7.5', () {
      final ScoreBreakdown s =
          estimateScore(createGame(BoardSize.s19), rules: GoRules.chinese);
      expect(s.komi, 7.5);
    });

    test('3 · 빈 판은 백이 덤 7.5 로 이긴다', () {
      final ScoreBreakdown s =
          estimateScore(createGame(BoardSize.s13), rules: GoRules.chinese);
      expect(s.winner, Stone.white);
      expect(s.margin, 7.5);
    });

    test('4 · 집계법과 달리 잡은 돌은 더하지 않는다', () {
      GameState g = createGame(BoardSize.s9);
      for (final (int, int) m in <(int, int)>[(1, 0), (0, 0), (0, 1), (8, 8)]) {
        g = (tryPlay(g, m.$1, m.$2) as PlayOk).state;
      }
      final ScoreBreakdown cn = estimateScore(g, rules: GoRules.chinese);
      // 잡은 돌은 보고는 하되 합계에는 안 들어간다
      expect(cn.blackCaptures, 1);
      expect(cn.blackTotal, cn.blackTerritory + cn.blackStones);
    });

    test('5 · 덤을 직접 지정하면 그 값을 쓴다', () {
      final ScoreBreakdown s = estimateScore(createGame(BoardSize.s19),
          rules: GoRules.chinese, komiOverride: 0);
      expect(s.komi, 0);
      expect(s.winner, isNull, reason: '덤 0 인 빈 판은 무승부');
    });
  });

  test('⚠ 사석을 판정하지 않는다 — 화면에 "추정" 표시가 필요한 이유', () {
    // 흑에게 완전히 둘러싸인 백 한 점. 실제로는 죽은 돌이지만
    // 이 함수는 살아 있는 것으로 센다.
    final GameState g = _from(<String>[
      '.b.......',
      'bwb......',
      '.b.......',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
    ]);
    final ScoreBreakdown s = estimateScore(g);
    expect(s.whiteStones, 1, reason: '죽은 돌도 판 위에 있으면 세어진다');

    // 이 함수: 빈 점 76 = 81 - 흑 4 - 백 1. 백돌이 아직 판에 있으므로
    //          그 자리 1점을 흑집에서 잃는다.
    // 정확한 일본룰: 죽은 백돌을 들어내고 흑집 77 + 사석 1 = 78.
    // 차이는 2점. 판이 클수록 사석이 늘어 오차도 커진다.
    expect(s.blackTerritory, 76);
    expect(s.blackTotal, 76,
        reason: '정확한 계가라면 78 이다 — 화면에 "추정" 표기가 필요한 이유');
  });
}
