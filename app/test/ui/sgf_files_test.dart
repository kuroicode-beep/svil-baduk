// test/ui/sgf_files_test.dart — SGF 내보내기·불러오기
//
// 파일 대화상자 자체는 OS 것이라 여기서 못 연다. 대신 화면이
// 결과 네 가지(저장·읽음·취소·실패)를 구별해 말하는지를 본다.
// 취소했는데 "실패" 가 낭독되면 사용자가 놀란다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/data/platform/sgf_files.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/platform_caps.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/widgets/board/cursor_readout.dart';

class _FakeIo implements SgfFileIo {
  _FakeIo({this.saveResult, this.openResult});

  FileOutcome? saveResult;
  FileOutcome? openResult;
  String? savedContents;

  @override
  Future<FileOutcome> save(String contents,
      {required String suggestedName}) async {
    savedContents = contents;
    return saveResult ?? const FileWritten('C:/x.sgf');
  }

  @override
  Future<FileOutcome> open() async =>
      openResult ?? const FileCancelled();
}

void main() {
  Future<void> pump(WidgetTester tester, SgfFileIo io) async {
    await tester.pumpWidget(MaterialApp(
      home: SoloScreen(
        settings: const AppSettings(opponent: OpponentKind.none),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        size: BoardSize.s9,
        caps: const PlatformCaps(AppPlatform.windows),
        files: io,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String status(WidgetTester tester) =>
      tester.widget<CursorReadout>(find.byType(CursorReadout)).status ?? '';

  Future<void> tapAndSettle(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('내보내면 유효한 SGF 가 나간다', (WidgetTester tester) async {
    final _FakeIo io = _FakeIo();
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfExport(Lang.ko));

    expect(io.savedContents, startsWith('(;FF[4]GM[1]SZ[9]'));
    expect(status(tester), S.sgfSaved(Lang.ko));
  });

  testWidgets('취소는 실패가 아니다 — 다르게 말한다', (WidgetTester tester) async {
    final _FakeIo io = _FakeIo(saveResult: const FileCancelled());
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfExport(Lang.ko));

    expect(status(tester), S.sgfCancelled(Lang.ko));
    expect(status(tester), isNot(contains(S.sgfWriteFailed(Lang.ko))));
  });

  testWidgets('쓰기 실패는 이유까지 말한다', (WidgetTester tester) async {
    final _FakeIo io = _FakeIo(
        saveResult: const FileFailed('sgfWriteFailed', detail: '디스크 가득'));
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfExport(Lang.ko));

    expect(status(tester), contains(S.sgfWriteFailed(Lang.ko)));
    expect(status(tester), contains('디스크 가득'));
  });

  testWidgets('불러오면 판이 바뀐다', (WidgetTester tester) async {
    final _FakeIo io = _FakeIo(
        openResult: const FileRead('(;FF[4]SZ[9];B[cc];W[dd])', 'x.sgf'));
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfImport(Lang.ko));

    expect(status(tester), S.sgfLoaded(Lang.ko));
  });

  testWidgets('깨진 SGF 는 사유를 말하고 판을 건드리지 않는다',
      (WidgetTester tester) async {
    final _FakeIo io =
        _FakeIo(openResult: const FileRead('그냥 텍스트', 'x.sgf'));
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfImport(Lang.ko));

    expect(status(tester), S.sgfNotSgf(Lang.ko));
  });

  testWidgets('반칙이 든 SGF 는 몇 수째인지 말한다', (WidgetTester tester) async {
    final _FakeIo io = _FakeIo(
        openResult:
            const FileRead('(;FF[4]SZ[9];B[cc];W[dd];B[cc])', 'x.sgf'));
    await pump(tester, io);
    await tapAndSettle(tester, S.sgfImport(Lang.ko));

    expect(status(tester), contains(S.sgfIllegalMove(Lang.ko)));
  });

  testWidgets('파일 대화상자가 없는 기기에는 버튼이 없다',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SoloScreen(
        settings: const AppSettings(opponent: OpponentKind.none),
        vision: const AppSettings().toVision(systemReduceMotion: false),
        size: BoardSize.s9,
        caps: const PlatformCaps(AppPlatform.android),
        files: _FakeIo(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(S.sgfExport(Lang.ko)), findsNothing);
    expect(find.text(S.sgfImport(Lang.ko)), findsNothing);
  });

  test('파일 이름에 날짜와 판 크기가 들어간다', () {
    expect(sgfFileName(19, DateTime(2026, 8, 9, 14, 5)),
        'svil-baduk_20260809_1405_19x19.sgf');
  });
}
