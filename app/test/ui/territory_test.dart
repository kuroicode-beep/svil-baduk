// test/ui/territory_test.dart — 계가 결과의 집 표시
//
// 접근성 기준: 색만으로 상태를 구분하지 않는다. 집은 사각형, 돌은 원이라
// 모양이 다르고, 공배는 아무것도 그리지 않아 "정해지지 않음" 이 드러난다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/scoring.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/ui/theme/board_theme.dart';
import 'package:svil_baduk/ui/widgets/board/board_painter.dart';

/// 캔버스에 그려진 사각형·원의 개수를 센다
class _CountingCanvas implements Canvas {
  int rects = 0;
  int circles = 0;

  @override
  void drawRect(Rect rect, Paint paint) => rects++;

  @override
  void drawCircle(Offset c, double radius, Paint paint) => circles++;

  @override
  void noSuchMethod(Invocation invocation) {}
}

BoardRenderModel model(GameState g, {List<Stone>? ownership}) =>
    BoardRenderModel(
      state: g,
      cursor: const Point(0, 0),
      armed: false,
      showCursor: false,
      lastMove: null,
      showCoords: false,
      lineWidth: 2,
      ownership: ownership,
    );

int rectsFor(BoardRenderModel m) {
  final _CountingCanvas c = _CountingCanvas();
  BoardPainter(model: m, palette: BoardPalette.byId(BoardPaletteId.classic))
      .paint(c, const Size(600, 600));
  return c.rects;
}

void main() {
  final GameState empty = createGame(BoardSize.s9);

  test('집 소유가 없으면 아무것도 더 그리지 않는다', () {
    expect(rectsFor(model(empty)), rectsFor(model(empty, ownership: null)));
  });

  test('집이 있으면 사각형이 늘어난다 — 돌(원)과 모양이 다르다', () {
    final int before = rectsFor(model(empty));
    final List<Stone> own = List<Stone>.filled(81, Stone.empty);
    own[0] = Stone.black;
    own[1] = Stone.white;
    final int after = rectsFor(model(empty, ownership: own));
    // 집 하나당 채움 + 테두리 = 사각형 2개
    expect(after - before, 4, reason: '집 2점이 사각형 4개가 되어야 합니다');
  });

  test('공배는 그리지 않는다 — 정해지지 않았음이 드러나야 한다', () {
    final int before = rectsFor(model(empty));
    final List<Stone> allNeutral = List<Stone>.filled(81, Stone.empty);
    expect(rectsFor(model(empty, ownership: allNeutral)), before);
  });

  test('돌이 놓인 자리에는 집을 안 그린다 — 돌을 가린다', () {
    final GameState g = (tryPlay(empty, 0, 0) as PlayOk).state;
    final List<Stone> own = List<Stone>.filled(81, Stone.black);
    final int withStone = rectsFor(model(g, ownership: own));
    final int withoutStone = rectsFor(model(g));
    // 80개 빈 점에만 그린다 (81 - 흑돌 1)
    expect(withStone - withoutStone, 80 * 2);
  });

  test('실제 계가 결과를 그대로 넘길 수 있다', () {
    final ScoreBreakdown s = estimateScore(empty);
    expect(s.ownership.length, 81);
    expect(() => rectsFor(model(empty, ownership: s.ownership)),
        returnsNormally);
  });

  test('설정과 엔진이 같은 GoRules 타입을 쓴다', () {
    // 두 곳에 같은 이름의 enum 이 있으면 서로 대입이 안 된다
    const AppSettings st = AppSettings(goRules: GoRules.chinese);
    final ScoreBreakdown s = estimateScore(empty, rules: st.goRules);
    expect(s.rules, GoRules.chinese);
  });
}
