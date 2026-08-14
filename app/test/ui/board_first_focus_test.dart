// test/ui/board_first_focus_test.dart
//
// NVDA 실측(2026-08-13): Semantics.hint 는 낭독되지 않는다. label 과 value 는
// 읽히지만 hint 는 MSAA 경로에서 유실된다. 그래서 조작 안내는 판이 처음
// 포커스를 받을 때 한 번 명시적으로 낭독한다. 이 테스트가 그 계약을 고정한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/ui/theme/board_theme.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';
import 'package:svil_baduk/ui/widgets/board/board_view.dart';

void main() {
  Future<BoardViewState> pump(WidgetTester tester, VoidCallback onFirst) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BoardView(
          state: createGame(BoardSize.s9),
          cursor: const Point(4, 4),
          armed: false,
          lastMove: null,
          palette: BoardPalette.byId(BoardPaletteId.classic),
          vision: const VisionSettings(),
          semanticsLabel: '판',
          semanticsValue: 'E5, 빈 점',
          semanticsHint: '힌트',
          interactive: true,
          coordMode: CoordDisplayMode.off,
          lineWidth: 2,
          onMoveCursor: (_, _) {},
          onSetCursor: (_) {},
          onIntent: (_) {},
          onFirstFocus: onFirst,
        ),
      ),
    ));
    await tester.pump();
    return tester.state<BoardViewState>(find.byType(BoardView));
  }

  testWidgets('첫 포커스에서 정확히 한 번 불린다', (WidgetTester tester) async {
    int calls = 0;
    final BoardViewState board = await pump(tester, () => calls++);
    expect(calls, 0, reason: '포커스 전에 불렸습니다');

    board.requestFocus();
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('포커스가 오가도 다시 불리지 않는다 — 매번 말하면 소음이다',
      (WidgetTester tester) async {
    int calls = 0;
    final BoardViewState board = await pump(tester, () => calls++);

    board.requestFocus();
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    board.requestFocus();
    await tester.pump();

    expect(calls, 1, reason: '재포커스마다 안내가 반복됩니다');
  });
}
