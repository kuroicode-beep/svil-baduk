// test/ui/app_boot_test.dart — 앱이 실제로 뜨고 화면이 연결돼 있는가
//
// 이 파일이 있는 이유: 3단계에서 만든 대국 화면이 6단계까지 main.dart 에
// 연결되지 않은 채로 있었다. 빌드도 되고 테스트도 통과했지만 앱을 켜면
// 스캐폴드 안내문만 나왔다. 화면 하나하나의 테스트로는 못 잡는다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/home_screen.dart';
import 'package:svil_baduk/ui/screens/learn_screen.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/screens/solo_setup_screen.dart';
import 'package:svil_baduk/version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 컨테이너 생성은 반드시 runAsync 안에서 한다.
  ///
  /// AppContainer.create 가 rootBundle 로 curriculum.json 을 읽는데,
  /// testWidgets 의 가짜 비동기 영역에서는 에셋 로딩이 돌아오지 않는다.
  /// (첫 테스트만 통과하고 그 뒤 전부 "did not complete" 로 멈춘다)
  Future<AppContainer> boot(
    WidgetTester tester, [
    Map<String, Object> initial = const <String, Object>{},
  ]) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(initial);
      return AppContainer.create(prefs: await SharedPreferences.getInstance());
    });
    return c!;
  }

  Future<void> pumpHome(WidgetTester tester, AppContainer c) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(container: c)));
    await tester.pumpAndSettle();
  }

  testWidgets('시작 화면에 버전이 늘 보인다 (하우스 규칙)',
      (WidgetTester tester) async {
    await pumpHome(tester, await boot(tester));
    expect(find.textContaining('v$appVersion'), findsOneWidget);
  });

  // 판은 교차점 깜빡임 애니메이션을 계속 돌린다 — pumpAndSettle 은
  // 영영 끝나지 않으므로 화면 전환에는 고정 시간 펌프를 쓴다.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('대국은 설정 화면을 거쳐 시작한다 (Stitch 기획 흐름)',
      (WidgetTester tester) async {
    await pumpHome(tester, await boot(tester));
    await tester.tap(find.text(S.solo(Lang.ko)));
    await settleRoute(tester);
    expect(find.byType(SoloSetupScreen), findsOneWidget,
        reason: '바로 판이 아니라 대국 설정이 먼저다');

    // 시작 버튼은 난이도 라디오 10개 아래라 화면 밖이다 — 스크롤해서 탭
    await tester.scrollUntilVisible(find.text(S.startGame(Lang.ko)), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text(S.startGame(Lang.ko)));
    await settleRoute(tester);
    expect(find.byType(SoloScreen), findsOneWidget);
  });

  testWidgets('배우기 화면으로 갈 수 있다', (WidgetTester tester) async {
    await pumpHome(tester, await boot(tester));
    await tester.tap(find.text(S.learn(Lang.ko)));
    await settleRoute(tester);
    expect(find.byType(LearnScreen), findsOneWidget);
  });

  testWidgets('교육 과정이 실려 있다 — 에셋 등록 누락을 잡는다',
      (WidgetTester tester) async {
    final AppContainer c = await boot(tester);
    expect(c.curriculum.problemCount, 28);
  });

  testWidgets('저장된 설정을 읽어 시작한다', (WidgetTester tester) async {
    final AppContainer c = await boot(tester, <String, Object>{
      'svil-baduk-settings': '{"v":1,"boardSize":9,"rankId":"lv7"}',
    });
    expect(c.settings.settings.boardSize.lines, 9);
    expect(c.settings.settings.rankId, 'lv7');
  });

  testWidgets('저장된 배우기 진행을 읽어 시작한다', (WidgetTester tester) async {
    final AppContainer c = await boot(tester, <String, Object>{
      'svil-baduk-learn-progress': '{"v":1,"solved":["x","y"]}',
    });
    expect(c.progress.solved, <String>{'x', 'y'});
  });

  testWidgets('진행을 저장하면 다시 켰을 때 남아 있다',
      (WidgetTester tester) async {
    final (AppContainer, AppContainer)? pair =
        await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppContainer a = await AppContainer.create(prefs: prefs);
      a.progress.save(<String>{'basics-1'});
      // 같은 저장소로 다시 켠다
      return (a, await AppContainer.create(prefs: prefs));
    });
    expect(pair!.$2.progress.solved, contains('basics-1'));
  });

  test('curriculum.json 이 pubspec 에 등록돼 있다', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/learn/'),
        reason: '에셋이 빠지면 앱은 빌드되지만 실행 시 배우기가 죽는다');
    expect(File('assets/learn/curriculum.json').existsSync(), isTrue);
  });
}
