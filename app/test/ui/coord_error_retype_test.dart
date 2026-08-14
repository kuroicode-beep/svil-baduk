// test/ui/coord_error_retype_test.dart
//
// NVDA 실측 1차(2026-08-13)에서 "I5 오류 → 텍스트 선택 유지 → Z99 이어 입력"
// 순서일 때 Z99 오류가 낭독되지 않는 현상이 한 번 관찰됐다. 클린 상태에선
// 정상이었다. 앱 경로가 건강하다면 그 현상은 키 주입 유실(측정 도구 쪽)이다.
// 이 테스트가 앱 경로를 고정한다 — 오류 연쇄에서도 매번 사유가 나와야 한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/platform_caps.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SoloScreen(
        settings: const AppSettings(opponent: OpponentKind.none),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        size: BoardSize.s19,
        caps: const PlatformCaps(AppPlatform.windows),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String status(WidgetTester tester) =>
      tester.widget<CursorReadout>(find.byType(CursorReadout)).status ?? '';

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('오류 연쇄 — I5 다음 Z99 도 각자 사유를 말한다',
      (WidgetTester tester) async {
    await pump(tester);

    await submit(tester, 'I5');
    final String first = status(tester);
    expect(first, isNotEmpty, reason: 'I5 오류가 침묵했습니다');

    // 선택 유지 상태에서 이어 입력 (enterText 는 선택을 덮어쓴다 — 실사용과 동일)
    await submit(tester, 'Z99');
    final String second = status(tester);
    expect(second, isNotEmpty, reason: 'Z99 오류가 침묵했습니다');
    expect(second, isNot(first), reason: '다른 오류인데 같은 문구입니다');
  });

  testWidgets('오류 셋 연달아 — 매번 새 사유', (WidgetTester tester) async {
    await pump(tester);
    final List<String> said = <String>[];
    for (final String bad in <String>['I5', 'Z99', 'A0']) {
      await submit(tester, bad);
      said.add(status(tester));
    }
    expect(said.where((String s) => s.isEmpty), isEmpty,
        reason: '침묵한 제출이 있습니다: $said');
  });

  testWidgets('오류 후 성공하면 입력이 비워진다 (A11)', (WidgetTester tester) async {
    await pump(tester);
    await submit(tester, 'I5');
    await submit(tester, 'D4');
    final TextField f = tester.widget<TextField>(find.byType(TextField));
    expect(f.controller!.text, isEmpty, reason: '성공 후에도 텍스트가 남았습니다');
  });

  testWidgets('오류 후 텍스트가 전체 선택으로 남는다 (A12)', (WidgetTester tester) async {
    await pump(tester);
    await submit(tester, 'Z99');
    final TextField f = tester.widget<TextField>(find.byType(TextField));
    expect(f.controller!.text, 'Z99', reason: '실패했는데 텍스트가 지워졌습니다');
    expect(f.controller!.selection.baseOffset, 0);
    expect(f.controller!.selection.extentOffset, 3, reason: '전체 선택이 아닙니다');
  });
}
