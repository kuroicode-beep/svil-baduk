// test/ui/learn_screen_test.dart — 배우기 화면
//
// 판 조작 자체는 board_view 테스트가 본다. 여기서는 화면이 컨트롤러를
// 제대로 엮었는지 — 진행이 저장되고, 잠긴 단계가 눌리지 않고,
// 오답이 침묵하지 않는지를 본다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/learn/curriculum.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/learn_screen.dart';
import 'package:svil_baduk/ui/widgets/board/board_view.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

void main() {
  late Curriculum curriculum;

  setUpAll(() {
    curriculum =
        Curriculum.parse(File('assets/learn/curriculum.json').readAsStringSync());
  });

  Future<Set<String>> pump(
    WidgetTester tester, {
    Set<String> solved = const <String>{},
  }) async {
    Set<String> saved = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: LearnScreen(
        curriculum: curriculum,
        settings: const AppSettings(),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        solved: solved,
        onProgress: (Set<String> s) => saved = s,
      ),
    ));
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets('세 트랙이 모두 보인다', (WidgetTester tester) async {
    await pump(tester);
    for (final String name in <String>[
      S.learnTrackBasics(Lang.ko),
      S.learnTrackFuseki(Lang.ko),
      S.learnTrackTsumego(Lang.ko),
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  testWidgets('잠긴 단계는 눌리지 않고, 잠김을 글로도 알린다',
      (WidgetTester tester) async {
    await pump(tester);
    // 색만으로 상태를 알리지 않는다 — 텍스트가 있어야 한다
    expect(find.text(S.learnLocked(Lang.ko)), findsWidgets);

    final Iterable<OutlinedButton> buttons =
        tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttons.where((OutlinedButton b) => b.onPressed == null), isNotEmpty,
        reason: '잠긴 단계가 눌립니다');
  });

  testWidgets('첫 단계는 열려 있어 문제로 들어간다', (WidgetTester tester) async {
    await pump(tester);
    final LearnStage first = curriculum.stages.first;
    await tester.tap(find.text(first.title('ko')));
    await tester.pumpAndSettle();
    // 문제 화면에는 다시 놓기 버튼이 있다
    expect(find.text(S.learnRetry(Lang.ko)), findsOneWidget);
  });

  /// 판에 포커스를 주고 엔터를 친다 — 스크린리더 사용자가 쓰는 실제 경로
  Future<void> placeAtCursor(WidgetTester tester) async {
    final BoardViewState board =
        tester.state<BoardViewState>(find.byType(BoardView));
    board.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  }

  testWidgets('키보드만으로 정답을 맞히면 진행이 저장된다',
      (WidgetTester tester) async {
    Set<String> saved = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: LearnScreen(
        curriculum: curriculum,
        settings: const AppSettings(),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        solved: const <String>{},
        onProgress: (Set<String> s) => saved = s,
      ),
    ));
    await tester.pumpAndSettle();

    final LearnStage first = curriculum.stages.first;
    await tester.tap(find.text(first.title('ko')));
    await tester.pumpAndSettle();

    // 정답 보기가 커서를 정답 자리로 옮긴다
    await tester.tap(find.text(S.learnShowAnswer(Lang.ko)));
    await tester.pumpAndSettle();
    await placeAtCursor(tester);

    expect(saved, contains(first.problems.first.id),
        reason: '정답을 맞혔는데 진행이 저장되지 않았습니다');
  });

  testWidgets('오답이 침묵하지 않는다 — 화면에도 남는다',
      (WidgetTester tester) async {
    await pump(tester);
    final LearnStage first = curriculum.stages.first;
    await tester.tap(find.text(first.title('ko')));
    await tester.pumpAndSettle();

    // 커서를 정답에서 멀리 옮긴다 (기본 위치는 판 한가운데)
    final BoardViewState board =
        tester.state<BoardViewState>(find.byType(BoardView));
    board.requestFocus();
    await tester.pump();
    for (int i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // 발화가 유실돼도 정보가 남도록 화면상 쌍둥이가 있어야 한다 (A20)
    final CursorReadout readout =
        tester.widget<CursorReadout>(find.byType(CursorReadout));
    expect(readout.status, isNotEmpty, reason: '결과를 화면에 남기지 않았습니다');
  });

  testWidgets('힌트를 누르면 힌트가 화면에 남는다 (발화 유실 대비)',
      (WidgetTester tester) async {
    await pump(tester);
    final LearnStage first = curriculum.stages.first;
    await tester.tap(find.text(first.title('ko')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.askHint(Lang.ko)));
    await tester.pumpAndSettle();

    expect(find.text(first.problems.first.hint('ko')), findsWidgets);
  });

  testWidgets('진행을 이어받으면 못 푼 문제부터 연다', (WidgetTester tester) async {
    final LearnStage s = curriculum.stages.first;
    await pump(tester, solved: <String>{s.problems.first.id});
    await tester.tap(find.text(s.title('ko')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/${s.problems.length}'), findsOneWidget);
  });
}
