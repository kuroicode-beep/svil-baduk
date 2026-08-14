// test/ui/opponent_reply_gap_test.dart
//
// NVDA 실측(2026-08-13): 내 착수 알림과 AI 응수 알림이 수 ms 간격으로 나가면
// 뒤엣것만 낭독된다. 내장 AI 는 저레벨에서 사실상 즉답이라, 응수 반영에
// 최소 간격(700ms)을 둬 내 착수가 들릴 시간을 확보한다. 이 테스트가
// "즉시 응수해도 내 착수 낭독이 먼저 살아 있다"를 고정한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/platform_caps.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

void main() {
  String status(WidgetTester tester) =>
      tester.widget<CursorReadout>(find.byType(CursorReadout)).status ?? '';

  testWidgets('AI 즉답이어도 내 착수가 먼저 화면·낭독 채널에 남는다',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SoloScreen(
        settings: const AppSettings(), // 기본: 내장 AI lv3
        vision: const AppSettings().toVision(systemReduceMotion: false),
        size: BoardSize.s9,
        caps: const PlatformCaps(AppPlatform.windows),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'D4');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 200ms 시점: 아직 내 착수만 — 내 문구는 '흑 D4…', 응수 문구는 '백 …'
    final String early = status(tester);
    expect(early, startsWith('흑 D4'),
        reason: '내 착수가 즉시 남지 않았거나 응수가 덮었습니다: $early');

    // 900ms 시점: 응수가 반영돼 있어야 한다 (기다림이 과해도 안 된다)
    await tester.pump(const Duration(milliseconds: 700));
    final String late = status(tester);
    expect(late, startsWith('백 '), reason: '응수가 반영되지 않았습니다: $late');
  });

  testWidgets('상대 없음이면 지연도 없다', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SoloScreen(
        settings: const AppSettings(opponent: OpponentKind.none),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        size: BoardSize.s9,
        caps: const PlatformCaps(AppPlatform.windows),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'D4');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(status(tester), contains('D4'));
  });
}
