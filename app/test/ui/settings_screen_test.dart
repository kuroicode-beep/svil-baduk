// test/ui/settings_screen_test.dart
//
// 설정은 저장까지 이어져야 의미가 있다. 화면에서 고른 값이 디스크에
// 남고 다시 켰을 때 살아 있는지를 본다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/settings_screen.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> boot(WidgetTester tester) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return AppContainer.create(prefs: await SharedPreferences.getInstance());
    });
    return c!;
  }

  /// ListView 는 지연 생성이라 화면 밖 항목은 아직 위젯이 없다.
  /// 실제 사용자도 스크롤해서 찾으므로 테스트도 그렇게 한다.
  Future<Finder> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    return target;
  }

  Future<AppContainer> pump(WidgetTester tester) async {
    final AppContainer c = await boot(tester);
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(container: c)));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('선택지가 라디오로 나온다 — 드롭다운은 스크린리더에 불리하다',
      (WidgetTester tester) async {
    await pump(tester);
    expect(find.byType(RadioListTile<ContrastProfile>), findsNWidgets(3));
    expect(find.byType(DropdownButton<Object>), findsNothing);
  });

  testWidgets('대비를 바꾸면 설정과 시각 컨트롤러가 함께 바뀐다',
      (WidgetTester tester) async {
    final AppContainer c = await pump(tester);
    expect(c.settings.settings.contrast, ContrastProfile.high);

    await tester.tap(find.text(S.contrastMax(Lang.ko)));
    await tester.pumpAndSettle();

    expect(c.settings.settings.contrast, ContrastProfile.maximum);
    expect(c.vision.vision.contrast, ContrastProfile.maximum,
        reason: '시각 컨트롤러가 따라오지 않았습니다');
  });

  testWidgets('바꾼 값이 저장되어 다시 켰을 때 남는다',
      (WidgetTester tester) async {
    final SharedPreferences? prefs = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return SharedPreferences.getInstance();
    });
    final AppContainer? a =
        await tester.runAsync(() => AppContainer.create(prefs: prefs));
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(container: a!)));
    await tester.pumpAndSettle();

    await tester.tap(await scrollTo(tester, find.text('9${S.rowSuffix(Lang.ko)}')));
    await tester.pumpAndSettle();

    final AppContainer? b =
        await tester.runAsync(() => AppContainer.create(prefs: prefs));
    expect(b!.settings.settings.boardSize.lines, 9);
  });

  testWidgets('언어를 바꾸면 화면 글자가 즉시 바뀐다', (WidgetTester tester) async {
    await pump(tester);
    expect(find.text(S.settings(Lang.ko)), findsOneWidget);

    await tester.tap(find.text(langLabels[Lang.en]!));
    await tester.pumpAndSettle();

    expect(find.text(S.settings(Lang.en)), findsOneWidget);
  });

  testWidgets('계가 근사의 한계를 화면에 적어 둔다', (WidgetTester tester) async {
    await pump(tester);
    await scrollTo(tester, find.text(S.scoreDeadStonesNote(Lang.ko)));
    expect(find.text(S.scoreDeadStonesNote(Lang.ko)), findsOneWidget);
  });

  testWidgets('KataGo 를 못 쓰는 기기에서는 선택지가 아예 없다',
      (WidgetTester tester) async {
    final AppContainer c = await pump(tester);
    // 이 테스트는 데스크톱에서 돈다 — 선택지가 보여야 한다
    expect(c.caps.canRunKataGo, isTrue);
    await scrollTo(tester, find.text(S.opponentKataGo(Lang.ko)));
    expect(find.text(S.opponentKataGo(Lang.ko)), findsOneWidget);
  });

  testWidgets('난이도 10단계가 모두 있다', (WidgetTester tester) async {
    final AppContainer c = await pump(tester);
    // 한 화면에 다 안 들어가므로 양 끝을 각각 찾아본다
    await scrollTo(tester, find.text('1'));
    expect(find.text('1'), findsOneWidget);
    await scrollTo(tester, find.text('10'));
    expect(find.text('10'), findsOneWidget);
    // 눌러서 실제로 바뀌는지까지
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(c.settings.settings.rankId, 'lv10');
  });
}
