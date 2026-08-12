// test/domain/builtin_ai_test.dart — 체크리스트 G10·G11
//
// 원본 TS 는 Math.random() 을 직접 불러서 이 검증이 불가능했다.
// Random 을 주입하도록 바꿨으므로 실패하면 시드로 재현할 수 있다.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/ai/builtin.dart';
import 'package:svil_baduk/domain/ai/ranks.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

void main() {
  group('G11 · 난이도 10단계', () {
    test('레벨 1~10 이 빠짐없이 있고 순서대로다', () {
      expect(kRanks.length, 10);
      for (int i = 0; i < kRanks.length; i++) {
        expect(kRanks[i].level, i + 1);
      }
    });

    test('레벨이 오르면 약해지지 않는다 — 무작위는 줄고 탐색은 는다', () {
      for (int i = 1; i < kRanks.length; i++) {
        expect(kRanks[i].randomness, lessThanOrEqualTo(kRanks[i - 1].randomness),
            reason: '${kRanks[i].id} 가 이전 레벨보다 더 무작위입니다');
        expect(kRanks[i].visits, greaterThanOrEqualTo(kRanks[i - 1].visits),
            reason: kRanks[i].id);
      }
    });

    test('입문~초급+ 는 KataGo 를 쓰지 않는다 — visits=1 도 너무 강하다', () {
      for (final String id in <String>['lv1', 'lv2', 'lv3', 'lv4']) {
        expect(usesKataGoEngine(id), isFalse, reason: id);
      }
      for (final String id in <String>['lv5', 'lv10']) {
        expect(usesKataGoEngine(id), isTrue, reason: id);
      }
    });

    test('모르는 난이도 id 는 기본값으로 떨어진다 (저장값 손상 대비)', () {
      expect(getRank('없는레벨').id, kDefaultRank);
      expect(getRank('').level, 3);
    });

    test('한 수 상한이 3.2초를 넘지 않는다 — 멈춘 것처럼 보이면 실패다', () {
      for (final RankOption r in kRanks) {
        expect(r.maxTime.inMilliseconds, lessThanOrEqualTo(3200), reason: r.id);
      }
    });
  });

  group('G10 · 반칙 없이 둔다', () {
    test('1000판 · 반칙 0 · 판이 끝날 때까지', () {
      int illegal = 0;
      int moves = 0;
      int finished = 0;

      for (int seed = 0; seed < 1000; seed++) {
        final math.Random rng = math.Random(seed);
        // 9줄로 돈다 — 1000판을 19줄로 돌리면 테스트가 분 단위가 된다
        GameState g = createGame(BoardSize.s9);
        final String rank = kRanks[seed % kRanks.length].id;

        for (int turn = 0; turn < 200 && !g.ended; turn++) {
          final Point? p = pickBuiltinMove(g, rank, rng: rng);
          if (p == null) {
            g = (passMove(g) as PlayOk).state;
            continue;
          }
          final PlayResult r = tryPlay(g, p.x, p.y);
          if (r is PlayErr) {
            illegal++;
            // 실패해도 계속 돌려 총 몇 건인지 본다
            g = (passMove(g) as PlayOk).state;
          } else {
            g = (r as PlayOk).state;
            moves++;
          }
        }
        if (g.ended) finished++;
      }

      expect(illegal, 0, reason: '반칙 $illegal 건 / 총 $moves 수');
      expect(moves, greaterThan(10000), reason: '판이 너무 일찍 끝났습니다');
      expect(finished, greaterThan(0), reason: '두 번 패스로 끝나는 판이 하나도 없습니다');
    });

    test('같은 시드면 같은 수 — 실패를 재현할 수 있다', () {
      final GameState g = createGame(BoardSize.s9);
      final Point? a = pickBuiltinMove(g, 'lv7', rng: math.Random(42));
      final Point? b = pickBuiltinMove(g, 'lv7', rng: math.Random(42));
      expect(a?.x, b?.x);
      expect(a?.y, b?.y);
    });

    test('둘 곳이 없으면 null 을 준다 (호출자가 패스로 처리)', () {
      // 판을 흑돌로 가득 채우면 백은 자살수만 남아 둘 곳이 없다
      final GameState full = createProblemState(
        size: BoardSize.s9,
        black: <Point>[
          for (int y = 0; y < 9; y++)
            for (int x = 0; x < 9; x++) Point(x, y),
        ],
        white: const <Point>[],
        toPlay: Stone.white,
      );
      expect(legalMoves(full), isEmpty);
      expect(pickBuiltinMove(full, 'lv1', rng: math.Random(1)), isNull);
    });
  });

  group('힌트 (결정적)', () {
    test('같은 판이면 항상 같은 추천 — 힌트가 흔들리면 안 된다', () {
      final GameState g = createGame(BoardSize.s9);
      final List<RankedMove> a = pickBuiltinTopMoves(g);
      final List<RankedMove> b = pickBuiltinTopMoves(g);
      expect(a.map((RankedMove m) => '${m.point.x},${m.point.y}').toList(),
          b.map((RankedMove m) => '${m.point.x},${m.point.y}').toList());
    });

    test('순위와 백분율이 낭독 가능한 값으로 나온다', () {
      final List<RankedMove> top = pickBuiltinTopMoves(createGame(BoardSize.s9));
      expect(top.length, 3);
      for (int i = 0; i < top.length; i++) {
        expect(top[i].rank, i + 1);
        expect(top[i].percent, inInclusiveRange(1, 100));
      }
      expect(top.first.percent, 100, reason: '1순위는 자기 자신 대비 100%');
    });

    test('따냄이 있으면 최우선으로 올라온다', () {
      // 백 한 점이 활로 하나만 남았다 — (0,0) 에 두면 잡는다
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(2, 0), Point(1, 1)],
        white: const <Point>[Point(1, 0), Point(0, 1)],
        toPlay: Stone.black,
      );
      final List<RankedMove> top = pickBuiltinTopMoves(g, n: 1);
      expect(top.first.point.x, 0);
      expect(top.first.point.y, 0);
    });

    test('둘 곳이 없으면 빈 목록', () {
      final GameState full = createProblemState(
        size: BoardSize.s9,
        black: <Point>[
          for (int y = 0; y < 9; y++)
            for (int x = 0; x < 9; x++) Point(x, y),
        ],
        white: const <Point>[],
        toPlay: Stone.white,
      );
      expect(pickBuiltinTopMoves(full), isEmpty);
    });
  });
}
