// test/domain/engine_diff_test.dart — TS 엔진과의 차분 검증
//
// 계획서 체크리스트 G1. 규칙 이식에서 가장 무서운 것은 "대체로 맞는" 엔진이다.
// TS 엔진(tools/engine_diff.mjs)이 무작위 500판을 두며 매 시점의 합법 지점
// 집합과 최종 상태를 남겨 두었고, 여기서 Dart 가 같은 수순을 재생하며
// 판정이 한 곳이라도 다르면 실패한다.
//
// fixture 재생성: node tools/engine_diff.mjs  (npm run engine:diff)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';

void main() {
  late List<dynamic> games;

  setUpAll(() {
    final File f = File('test/fixtures/engine_diff.json');
    expect(f.existsSync(), isTrue,
        reason: 'fixture 가 없습니다 — node tools/engine_diff.mjs 를 먼저 돌리세요');
    games = (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)['games']
        as List<dynamic>;
  });

  test('G1 · 무작위 500판에서 합법성 판정이 TS 엔진과 완전히 일치한다', () {
    int checkedPoints = 0;
    int checkedMoves = 0;

    for (final dynamic raw in games) {
      final Map<String, dynamic> game = raw as Map<String, dynamic>;
      final int seed = game['seed'] as int;
      final BoardSize size = BoardSize.fromLines(game['size'] as int);
      final List<dynamic> moves = game['moves'] as List<dynamic>;
      final List<dynamic> checks = game['checks'] as List<dynamic>;

      // ply → 그 시점의 합법 지점 집합
      final Map<int, Set<String>> expectedLegal = <int, Set<String>>{};
      for (final dynamic c in checks) {
        final Map<String, dynamic> check = c as Map<String, dynamic>;
        expectedLegal[check['ply'] as int] = <String>{
          for (final dynamic p in check['legal'] as List<dynamic>)
            '${(p as List<dynamic>)[0]},${p[1]}',
        };
      }

      GameState g = createGame(size);
      for (int ply = 0; ply < moves.length; ply++) {
        final Map<String, dynamic> m = moves[ply] as Map<String, dynamic>;

        final Set<String>? want = expectedLegal[ply];
        if (want != null) {
          final Set<String> got =
              legalMoves(g).map((Point p) => '${p.x},${p.y}').toSet();
          expect(got, want,
              reason: 'seed $seed, ${size.lines}줄, $ply 수 시점에서 '
                  '합법 지점 집합이 다릅니다');
          checkedPoints += want.length;
        }

        final PlayResult r = (m['pass'] == true)
            ? passMove(g)
            : tryPlay(g, m['x'] as int, m['y'] as int);
        expect(r, isA<PlayOk>(),
            reason: 'seed $seed, $ply 수: TS 가 둔 수를 Dart 가 거부했습니다');
        g = (r as PlayOk).state;
        checkedMoves++;
      }

      // 최종 상태 대조
      final Map<String, dynamic> fin = game['final'] as Map<String, dynamic>;
      final List<dynamic> wantBoard = fin['board'] as List<dynamic>;
      for (int i = 0; i < wantBoard.length; i++) {
        expect(g.board[i], wantBoard[i],
            reason: 'seed $seed: 최종 판이 다릅니다 (index $i)');
      }
      expect(g.toPlay.wire, fin['toPlay'], reason: 'seed $seed: 차례가 다릅니다');
      expect(g.blackCaptures, fin['blackCaptures'],
          reason: 'seed $seed: 흑 따냄 수가 다릅니다');
      expect(g.whiteCaptures, fin['whiteCaptures'],
          reason: 'seed $seed: 백 따냄 수가 다릅니다');
      expect(g.ended, fin['ended'], reason: 'seed $seed: 종국 여부가 다릅니다');
      expect(g.consecutivePasses, fin['consecutivePasses'],
          reason: 'seed $seed: 연속 패스 수가 다릅니다');
    }

    // 검증량이 유의미한지도 확인 — fixture 가 비어도 통과하면 안 된다
    expect(games.length, greaterThanOrEqualTo(500));
    expect(checkedMoves, greaterThan(10000));
    expect(checkedPoints, greaterThan(100000));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
