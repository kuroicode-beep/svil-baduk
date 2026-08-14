// test/ui/home_revamp_test.dart — Stitch 기획 복원 검증
//
// 홈에 메뉴 5개(P2P 는 준비 중)·프로필 카드·도움말이 있어야 하고,
// 대국 종료가 전적·경험치에 반영돼야 한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/platform_caps.dart';
import 'package:svil_baduk/domain/profile/profile.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/character_screen.dart';
import 'package:svil_baduk/ui/screens/home_screen.dart';
import 'package:svil_baduk/ui/screens/multi_screen.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';

import '../support/loopback_p2p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> boot(WidgetTester tester,
      [Map<String, Object> initial = const <String, Object>{}]) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(initial);
      return AppContainer.create(
        prefs: await SharedPreferences.getInstance(),
        // 실 WebSocket 이 위젯 테스트의 FakeAsync 를 멈추게 하므로 가짜를 쓴다
        makeEndpoint: () => FakeEndpoint(FakeBrokerRegistry()),
      );
    });
    return c!;
  }

  Future<void> pumpHome(WidgetTester tester, AppContainer c) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(container: c)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('홈 구조 (Stitch)', () {
    testWidgets('메뉴 5개가 전부 있다', (WidgetTester tester) async {
      await pumpHome(tester, await boot(tester));
      for (final String label in <String>[
        S.solo(Lang.ko),
        S.learn(Lang.ko),
        S.menuMulti(Lang.ko),
        S.menuCharacter(Lang.ko),
        S.settings(Lang.ko),
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('상대랑 두기 타일이 P2P 로비를 연다 (0.18.0 — 준비 중 해제)',
        (WidgetTester tester) async {
      await pumpHome(tester, await boot(tester));
      expect(find.text(S.comingSoon(Lang.ko)), findsNothing,
          reason: '전송 계층이 생겼으니 준비 중 표기는 사라져야 한다');

      // 모든 타일이 포커스 가능해야 한다 (비활성은 Tab 이 건너뛴다 — NVDA 실측)
      final Iterable<OutlinedButton> disabled = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .where((OutlinedButton b) => b.onPressed == null);
      expect(disabled, isEmpty, reason: '포커스 불가 타일이 있습니다');

      await tester.tap(find.text(S.menuMulti(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MultiScreen), findsOneWidget,
          reason: '타일이 P2P 로비로 이어져야 한다');
      expect(find.text(S.yourId(Lang.ko)), findsOneWidget);
    });

    testWidgets('타일은 밝은 채움 버튼이 아니다 — 대비 회귀 방지',
        (WidgetTester tester) async {
      // 0.16.1 스크린샷: 밝은 파랑 채움 버튼 위 회색 보조 텍스트 = 대비 붕괴.
      // 홈 타일은 어두운 표면(OutlinedButton)이어야 한다.
      await pumpHome(tester, await boot(tester));
      expect(find.byType(OutlinedButton), findsNWidgets(5));
      expect(find.byType(FilledButton), findsNothing,
          reason: '홈에 밝은 채움 타일이 돌아왔습니다');
    });

    testWidgets('프로필 카드 — 별명·급수·레벨·전적·경험치가 한 라벨로 낭독된다',
        (WidgetTester tester) async {
      final AppContainer c = await boot(tester, <String, Object>{
        'svil-baduk-profile':
            '{"name":"돌이","level":3,"xp":20,"wins":5,"losses":2,'
                '"draws":0,"highScore":42,"bestAiLevel":4,"gamesPlayed":7}',
      });
      await pumpHome(tester, c);
      expect(find.text('돌이'), findsOneWidget);
      // 급수: bestAiLevel 4 → 9급
      expect(
        find.bySemanticsLabel(RegExp('돌이, 9급.*레벨 3.*5승 2패 0무.*경험치 20/130')),
        findsOneWidget,
        reason: '프로필 요약이 한 문장으로 낭독돼야 한다',
      );
    });

    testWidgets('도움말 버튼이 조작법을 연다', (WidgetTester tester) async {
      await pumpHome(tester, await boot(tester));
      await tester.tap(find.byTooltip(S.menuHelp(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining(S.boardHint(Lang.ko)), findsWidgets);
    });
  });

  group('전적 기록', () {
    testWidgets('AI 대국에서 기권하면 패배가 기록되고 경험치가 오른다',
        (WidgetTester tester) async {
      final AppContainer c = await boot(tester);
      expect(c.profile.profile.gamesPlayed, 0);

      await tester.pumpWidget(MaterialApp(
        home: SoloScreen(
          settings: const AppSettings(), // 내장 AI lv3
          vision: const AppSettings().toVision(systemReduceMotion: false),
          size: BoardSize.s9,
          caps: const PlatformCaps(AppPlatform.windows),
          profileCtrl: c.profile,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.scrollUntilVisible(find.text(S.resign(Lang.ko)), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(find.text(S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // 기권은 확인창 경유 (A15)
      await tester.tap(find.widgetWithText(TextButton, S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Profile p = c.profile.profile;
      expect(p.gamesPlayed, 1);
      expect(p.losses, 1, reason: '흑이 기권했으니 패배다');
      expect(p.xp, greaterThan(0), reason: '패배도 경험치를 준다');
    });

    testWidgets('상대 없음(혼자 두기)은 기록하지 않는다', (WidgetTester tester) async {
      final AppContainer c = await boot(tester);
      await tester.pumpWidget(MaterialApp(
        home: SoloScreen(
          settings: const AppSettings(opponent: OpponentKind.none),
          vision: const AppSettings().toVision(systemReduceMotion: false),
          size: BoardSize.s9,
          caps: const PlatformCaps(AppPlatform.windows),
          profileCtrl: c.profile,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(find.text(S.resign(Lang.ko)), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(find.text(S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.profile.profile.gamesPlayed, 0,
          reason: '양쪽 다 사람인 판이 전적에 들어가면 안 된다');
    });
  });

  group('캐릭터 화면', () {
    testWidgets('별명을 저장하면 유지된다', (WidgetTester tester) async {
      final AppContainer c = await boot(tester);
      await tester.pumpWidget(
          MaterialApp(home: CharacterScreen(container: c)));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '  인블루  ');
      await tester.tap(find.text(S.profileSave(Lang.ko)));
      await tester.pump();

      expect(c.profile.profile.name, '인블루', reason: '공백은 다듬어 저장');
      expect(c.profile.profile.createdAt, isNotNull);
    });

    testWidgets('빈 별명은 거절한다', (WidgetTester tester) async {
      final AppContainer c = await boot(tester);
      await tester.pumpWidget(
          MaterialApp(home: CharacterScreen(container: c)));
      await tester.pump();
      await tester.tap(find.text(S.profileSave(Lang.ko)));
      await tester.pump();
      expect(find.text(S.profileNameRequired(Lang.ko)), findsOneWidget);
      expect(c.profile.profile.name, isEmpty);
    });

    testWidgets('급수·레벨·경험치·전적이 표시된다', (WidgetTester tester) async {
      final AppContainer c = await boot(tester, <String, Object>{
        'svil-baduk-profile':
            '{"name":"돌이","level":2,"xp":30,"wins":3,"losses":1,'
                '"draws":1,"highScore":18,"bestAiLevel":9,"gamesPlayed":5}',
      });
      await tester.pumpWidget(
          MaterialApp(home: CharacterScreen(container: c)));
      await tester.pump();

      expect(find.text('1단'), findsOneWidget, reason: 'bestAiLevel 9 → 초단');
      expect(find.text('2'), findsWidgets); // 레벨
      expect(find.textContaining('30 / 100'), findsOneWidget); // XP
      expect(find.text('3승 1패 1무'), findsOneWidget);
    });
  });
}
