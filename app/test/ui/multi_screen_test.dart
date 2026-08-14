// test/ui/multi_screen_test.dart — 상대랑 두기 화면 (체크리스트 P6·A7·A15)
//
// 가짜 전송으로 로비→핸드셰이크→대국→끊김까지. 상대편은 화면 없이
// MultiController 를 직접 돌린다 — 같은 프로토콜을 말하는 원격이다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/application/game_controller.dart';
import 'package:svil_baduk/application/multi_controller.dart';
import 'package:svil_baduk/domain/engine/board.dart' show pointLabel;
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/multi_screen.dart';
import 'package:svil_baduk/ui/widgets/board/board_view.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

import '../support/loopback_p2p.dart';
import '../support/speech_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBrokerRegistry registry;
  late FakeEndpoint screenEp;

  Future<AppContainer> boot(WidgetTester tester) async {
    registry = FakeBrokerRegistry();
    screenEp = FakeEndpoint(registry, fixedId: 'svb-abc234');
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      return AppContainer.create(
        prefs: await SharedPreferences.getInstance(),
        makeEndpoint: () => screenEp,
      );
    });
    return c!;
  }

  Future<void> pumpMulti(WidgetTester tester, AppContainer c) async {
    // 로비는 ListView(지연 빌드)다 — 창을 키워 전부 화면에 들어오게 한다
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MultiScreen(container: c, makeEndpoint: c.makeEndpoint),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 루프백 마이크로태스크(가짜·실제 두 존)를 모두 흘려보낸다
  Future<void> drain(WidgetTester tester) async {
    for (int i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 화면 없는 원격 상대 — 게스트로 들어온다
  Future<MultiController> joinAsGuest(WidgetTester tester,
      {List<MultiSessionEvent>? events}) async {
    final MultiController guest = MultiController(
      endpoint: FakeEndpoint(registry, fixedId: 'svb-guest99'),
      makeGame: (BoardSize size) => GameController(
        size: size,
        speech: testSpeech,
        moveErrorPhrase: (MoveError e) => e.name,
        coordErrorPhrase: (_, int lines) => '입력 오류',
      ),
      onSession: events?.add,
    );
    await tester.runAsync(() async {
      await guest.openRoom();
      await guest.join('svb-abc234');
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return guest;
  }

  group('로비', () {
    testWidgets('내 방 ID 가 보이고 한 글자씩 낭독된다 (P6)',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      expect(find.text('svb-abc234'), findsOneWidget);
      // 시맨틱 라벨은 쉼표로 끊은 글자들 — 스크린리더가 철자로 읽는다
      expect(
        find.bySemanticsLabel('s, v, b, -, a, b, c, 2, 3, 4'),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsOneWidget, reason: 'QR (P7)');
      expect(find.text(S.copyId(Lang.ko)), findsOneWidget);
      expect(find.text(S.crossPlayNote(Lang.ko)), findsOneWidget,
          reason: '웹 판과 안 이어진다는 사실은 로비에 명시한다');
    });

    testWidgets('없는 방에 들어가면 오류가 낭독되고 로비에 남는다',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      await tester.enterText(find.byType(TextField), 'svb-nothere');
      await tester.tap(find.text(S.joinRoom(Lang.ko)), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BoardView), findsNothing);
      final CursorReadout readout =
          tester.widget<CursorReadout>(find.byType(CursorReadout));
      expect(readout.status, contains(S.connectFailed(Lang.ko)));
    });
  });

  group('대국', () {
    testWidgets('게스트가 들어오면 대국으로 넘어가고 연결·색이 낭독된다',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      await joinAsGuest(tester);

      expect(find.byType(BoardView), findsOneWidget);
      final CursorReadout readout =
          tester.widget<CursorReadout>(find.byType(CursorReadout));
      expect(readout.status, contains(S.connected(Lang.ko)));
      expect(readout.status, contains(S.black(Lang.ko)),
          reason: '호스트 기본 색은 흑');
      expect(find.text(S.yourTurn(Lang.ko)), findsOneWidget);
    });

    testWidgets('좌표 입력으로 착수하면 상대 판에 반영된다 (P2)',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      final MultiController guest = await joinAsGuest(tester);

      await tester.enterText(find.byType(TextField), 'D4');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await drain(tester);

      final Move landed = guest.game.state.history.single;
      expect(landed.player, Stone.black);
      expect(pointLabel(landed.x, landed.y, 9), 'D4',
          reason: '내 수가 같은 자리로 상대 판에 닿아야 한다');
      expect(find.text(S.opponentTurn(Lang.ko)), findsOneWidget);
    });

    testWidgets('상대 수가 포커스와 무관하게 낭독·표시된다 (A7)',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      final MultiController guest = await joinAsGuest(tester);

      // 내가 두고 — 상대가 응수한다
      await tester.enterText(find.byType(TextField), 'D4');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await drain(tester);
      guest.placeAt(5, 5);
      await drain(tester);

      final CursorReadout readout =
          tester.widget<CursorReadout>(find.byType(CursorReadout));
      expect(readout.status, contains('백'),
          reason: '상대(백) 수가 화면상 쌍둥이에 남아야 한다');
      expect(find.text(S.yourTurn(Lang.ko)), findsOneWidget);
    });

    testWidgets('기권은 확인창을 거치고, 상대 판까지 끝낸다 (A15)',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      final MultiController guest = await joinAsGuest(tester);

      await tester.tap(find.text(S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(S.resignConfirmTitle(Lang.ko)), findsOneWidget,
          reason: '기권은 한 번의 탭으로 끝나면 안 된다');

      // 취소하면 아무 일도 없다
      await tester.tap(find.widgetWithText(TextButton, S.cancel(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(guest.game.state.ended, isFalse);

      // 확인하면 양쪽 다 끝난다
      await tester.tap(find.text(S.resign(Lang.ko)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, S.resign(Lang.ko)));
      await drain(tester);

      expect(guest.game.state.ended, isTrue);
      expect(guest.game.state.resignedBy, Stone.black);
    });

    testWidgets('상대가 끊기면 화면이 알린다 (P4 표시 경로)',
        (WidgetTester tester) async {
      await pumpMulti(tester, await boot(tester));
      final MultiController guest = await joinAsGuest(tester);

      await tester.runAsync(() => guest.leaveGame());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(S.disconnected(Lang.ko)), findsWidgets,
          reason: '끊김이 침묵하면 안 된다');
    });
  });
}
