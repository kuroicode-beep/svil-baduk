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
import 'package:svil_baduk/ui/screens/solo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> boot(WidgetTester tester,
      [Map<String, Object> initial = const <String, Object>{}]) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(initial);
      return AppContainer.create(prefs: await SharedPreferences.getInstance());
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

    testWidgets('P2P 는 준비 중으로 비활성 — 낭독 라벨에도 담긴다',
        (WidgetTester tester) async {
      await pumpHome(tester, await boot(tester));
      expect(find.text(S.comingSoon(Lang.ko)), findsOneWidget);

      // 비활성 버튼은 Tab 이 건너뛰어 스크린리더가 발견 못 한다(NVDA 실측) —
      // 준비 중 타일도 포커스 가능해야 하고, 누르면 준비 중임을 알린다.
      final Iterable<OutlinedButton> disabled = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .where((OutlinedButton b) => b.onPressed == null);
      expect(disabled, isEmpty, reason: '포커스 불가 타일이 있습니다');

      await tester.tap(find.text(S.menuMulti(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining(S.comingSoon(Lang.ko)), findsWidgets,
          reason: '눌렀을 때 준비 중임을 알려야 한다');

      // 스크린리더가 "준비 중" 을 듣는가 — 시맨틱 라벨로 확인
      expect(
        find.bySemanticsLabel(
            '${S.menuMulti(Lang.ko)}, ${S.comingSoon(Lang.ko)}'),
        findsOneWidget,
      );
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
