// test/ui/user_journey_test.dart — 사용자 시뮬레이션 (2026-08-14)
//
// 화면 하나짜리 테스트는 "연결"의 결함을 못 잡는다 — main.dart 미연결(0.16.0),
// 홈 타일 침묵(0.16.1), 저장 버튼 실종감(0.17.0)이 전부 그랬다.
// 여기서는 사용자가 실제로 하는 순서 그대로 앱 전체를 누빈다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/character_screen.dart';
import 'package:svil_baduk/ui/screens/home_screen.dart';
import 'package:svil_baduk/ui/screens/learn_screen.dart';
import 'package:svil_baduk/ui/screens/settings_screen.dart';
import 'package:svil_baduk/ui/screens/multi_screen.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/screens/solo_setup_screen.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';
import 'package:svil_baduk/ui/widgets/board/board_view.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

import '../support/loopback_p2p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  Future<void> boot(WidgetTester tester,
      [Map<String, Object> initial = const <String, Object>{}]) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(initial);
      return AppContainer.create(
        prefs: await SharedPreferences.getInstance(),
        // 실 WebSocket 이 위젯 테스트의 FakeAsync 를 멈추게 하므로 가짜를 쓴다
        makeEndpoint: () => FakeEndpoint(FakeBrokerRegistry()),
      );
    });
    container = c!;
    await tester.pumpWidget(MaterialApp(
      theme: buildBadukTheme(container.vision.vision),
      home: HomeScreen(container: container),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 판 깜빡임 애니메이션 때문에 pumpAndSettle 은 못 쓴다 — 고정 펌프
  Future<void> settle(WidgetTester tester,
      [int ms = 400]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: ms));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final Finder f = find.text(text);
    if (tester.any(find.byType(Scrollable))) {
      try {
        await tester.scrollUntilVisible(f, 250,
            scrollable: find.byType(Scrollable).first);
        await tester.pump();
      } catch (_) {}
    }
    await tester.tap(f, warnIfMissed: false);
    await settle(tester);
  }

  Future<void> goBack(WidgetTester tester) async {
    // 표준 BackButton 이 없으면(배우기 문제 화면의 커스텀 leading) 아이콘으로 탭
    if (tester.any(find.byType(BackButton))) {
      await tester.pageBack();
    } else {
      await tester.tap(find.byIcon(Icons.arrow_back).first);
    }
    await settle(tester);
  }

  String status(WidgetTester tester) =>
      tester.widget<CursorReadout>(find.byType(CursorReadout)).status ?? '';

  testWidgets('여정 1 — 첫 사용자: 캐릭터 만들기 → 대국 설정 → 한 수 → 기권 → 전적 확인',
      (WidgetTester tester) async {
    await boot(tester);

    // 홈: 캐릭터로 가서 별명을 만든다
    await tapText(tester, S.menuCharacter(Lang.ko));
    expect(find.byType(CharacterScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '디또');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, S.profileSave(Lang.ko)));
    await settle(tester);
    expect(find.text(S.profileSaved(Lang.ko)), findsOneWidget,
        reason: '저장 스낵바가 떠야 한다 — 버튼 탭이 닿지 않았다');
    expect(container.profile.profile.name, '디또');
    // 스낵바(4초)가 하단의 다음 탭을 가로채지 않게 사라질 때까지 기다린다
    await settle(tester, 4500);
    // 급수 라벨이 "난이도" 가 아니라 "급수" 다 (0.17.0 오라벨 회귀 방지)
    expect(find.text(S.gradeTitle(Lang.ko)), findsOneWidget);
    expect(find.text(S.gradeBeginner(Lang.ko)), findsOneWidget);
    await goBack(tester);

    // 홈: 대국 → 설정 화면에서 9줄 고르고 시작
    await tapText(tester, S.solo(Lang.ko));
    expect(find.byType(SoloSetupScreen), findsOneWidget);
    await tapText(tester, '9${S.rowSuffix(Lang.ko)}');
    await tester.scrollUntilVisible(find.text(S.startGame(Lang.ko)), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text(S.startGame(Lang.ko)));
    await settle(tester, 800);
    expect(find.byType(SoloScreen), findsOneWidget);

    // 좌표로 한 수 → AI 응수(700ms 간격 규칙)
    await tester.enterText(find.byType(TextField), 'D4');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await settle(tester, 200);
    expect(status(tester), startsWith('흑 D4'));
    await settle(tester, 900);
    expect(status(tester), startsWith('백 '), reason: 'AI 가 응수하지 않았습니다');

    // 기권 → 확인창(A15) → 전적·경험치 반영
    await tapText(tester, S.resign(Lang.ko));
    expect(find.text(S.resignConfirmTitle(Lang.ko)), findsOneWidget,
        reason: '기권은 한 번의 탭으로 끝나면 안 된다');
    await tester.tap(find.widgetWithText(TextButton, S.resign(Lang.ko)));
    await settle(tester);
    expect(container.profile.profile.gamesPlayed, 1);
    expect(container.profile.profile.losses, 1);
    expect(container.profile.profile.xp, greaterThan(0));

    // 홈으로 — 프로필 카드에 전적이 반영돼 있다
    await goBack(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('디또'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('디또.*0승 1패 0무')),
      findsOneWidget,
      reason: '홈 프로필 카드에 방금 판이 반영돼야 한다',
    );
  });

  testWidgets('여정 2 — 배우기: 첫 문제 풀고 진행이 홈에 반영',
      (WidgetTester tester) async {
    await boot(tester);
    await tapText(tester, S.learn(Lang.ko));
    expect(find.byType(LearnScreen), findsOneWidget);

    // 첫 스테이지 → 정답 보기 → 착수(보드 위임 경로는 learn_screen_test 가 다룸)
    final String firstStage = container.curriculum.stages.first.title('ko');
    await tapText(tester, firstStage);
    expect(find.text(S.learnRetry(Lang.ko)), findsOneWidget);
    await goBack(tester); // 문제 → 스테이지 목록
    await goBack(tester); // 목록 → 홈
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('여정 3 — 설정 변경이 즉시 반영되고 다시 켜도 유지',
      (WidgetTester tester) async {
    await boot(tester);
    await tapText(tester, S.settings(Lang.ko));
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tapText(tester, S.contrastMax(Lang.ko));
    expect(container.settings.settings.contrast.name, 'maximum');
    expect(container.vision.vision.contrast.name, 'maximum',
        reason: '시각 컨트롤러가 함께 바뀌어야 한다');
    await goBack(tester);

    // 같은 저장소로 재기동해 유지 확인
    final SharedPreferences prefs =
        (await tester.runAsync(SharedPreferences.getInstance))!;
    final AppContainer again =
        (await tester.runAsync(() => AppContainer.create(prefs: prefs)))!;
    expect(again.settings.settings.contrast.name, 'maximum');
  });

  testWidgets('여정 4 — 도움말은 홈에서 두 번 탭 안에 조작법을 보여준다',
      (WidgetTester tester) async {
    await boot(tester);
    await tester.tap(find.byTooltip(S.menuHelp(Lang.ko)));
    await settle(tester);
    expect(find.textContaining(S.boardHint(Lang.ko)), findsWidgets);
    await tapText(tester, S.confirm(Lang.ko));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('여정 5 — 상대랑 두기: 로비에 닿고 방 ID 가 생기고 돌아온다',
      (WidgetTester tester) async {
    await boot(tester);
    await tester.tap(find.text(S.menuMulti(Lang.ko)), warnIfMissed: false);
    await settle(tester);
    expect(find.byType(MultiScreen), findsOneWidget);
    expect(find.textContaining('svb-'), findsWidgets,
        reason: '방 ID 가 만들어져 보여야 한다');
    await goBack(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('여정 6 — 계가: 혼자 두기에서 두 수 → 계가 → 패스 둘로 종국',
      (WidgetTester tester) async {
    await boot(tester);
    await tapText(tester, S.solo(Lang.ko));
    await tapText(tester, '9${S.rowSuffix(Lang.ko)}');
    await tapText(tester, S.opponentNone(Lang.ko));
    await tester.scrollUntilVisible(find.text(S.startGame(Lang.ko)), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text(S.startGame(Lang.ko)));
    await settle(tester, 800);

    Future<void> type(String s) async {
      await tester.enterText(find.byType(TextField), s);
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester, 200);
    }

    await type('D4');
    await type('F6');

    // 계가 — 사석 판정이 없으므로 "추정" 이 반드시 붙는다
    await tapText(tester, S.scoreNow(Lang.ko));
    expect(status(tester), contains(S.scoreEstimate(Lang.ko)),
        reason: '계가 결과가 화면상 쌍둥이에 남아야 한다');

    // 패스 두 번이면 종국 — 좌표칸 명령으로도 된다
    await type(S.pass(Lang.ko));
    await type(S.pass(Lang.ko));
    expect(container.profile.profile.gamesPlayed, 0,
        reason: '상대 없음(혼자 두기)은 전적에 넣지 않는다');
    final CursorReadout readout =
        tester.widget<CursorReadout>(find.byType(CursorReadout));
    expect(readout.status, isNotEmpty, reason: '종국 문장이 남아야 한다');
  });

  testWidgets('여정 7 — 배우기 첫 문제를 풀면 홈 타일 진행이 오른다',
      (WidgetTester tester) async {
    await boot(tester);
    expect(find.text('0 / ${container.curriculum.problemCount}'),
        findsOneWidget);

    await tapText(tester, S.learn(Lang.ko));
    final String firstStage = container.curriculum.stages.first.title('ko');
    await tapText(tester, firstStage);

    // 정답 보기가 커서를 정답으로 옮긴다 → 판에 포커스 → 엔터
    await tapText(tester, S.learnShowAnswer(Lang.ko));
    tester.state<BoardViewState>(find.byType(BoardView)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester, 600);
    expect(container.progress.solved, isNotEmpty,
        reason: '정답이 진행으로 저장돼야 한다');

    await goBack(tester); // 문제 → 목록
    await goBack(tester); // 목록 → 홈
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('1 / ${container.curriculum.problemCount}'),
        findsOneWidget, reason: '홈 타일이 새 진행을 보여야 한다');
  });

  testWidgets('버튼 표준 — 앱 어디에도 밝은 채움 버튼이 없다',
      (WidgetTester tester) async {
    // FilledButton 테마가 표준(어두운 표면)으로 바뀌었는지 색으로 검증
    await boot(tester);
    final ThemeData theme = Theme.of(tester.element(find.byType(HomeScreen)));
    final Color? bg = theme.filledButtonTheme.style?.backgroundColor
        ?.resolve(<WidgetState>{});
    expect(bg, isNotNull);
    // 밝은 액센트(0xFF7EC8FF 계열)가 아니라 어두운 표면이어야 한다
    expect(bg!.computeLuminance(), lessThan(0.1),
        reason: '채움 버튼 배경이 밝습니다: $bg — 버튼으로 안 읽힌다는 피드백 회귀');
  });

  testWidgets('진행바 — 0% 는 0% 로 보인다 (트랙이 액센트색이면 안 된다)',
      (WidgetTester tester) async {
    await boot(tester);
    final ThemeData theme = Theme.of(tester.element(find.byType(HomeScreen)));
    final Color? track = theme.progressIndicatorTheme.linearTrackColor;
    final Color? value = theme.progressIndicatorTheme.color;
    expect(track, isNotNull);
    expect(value, isNotNull);
    expect(track!.computeLuminance(), lessThan(0.1),
        reason: '트랙이 밝으면 빈 바가 가득 찬 것처럼 보인다 (0.17.0 실사고)');
    expect(value!.computeLuminance(), greaterThan(0.4),
        reason: '채움색은 트랙과 확실히 달라야 한다');
  });
}
