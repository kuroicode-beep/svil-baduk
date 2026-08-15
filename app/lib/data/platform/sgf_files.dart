// lib/data/platform/sgf_files.dart — SGF 파일 읽기·쓰기
//
// 파일 대화상자는 데스크톱에만 있다(platform_caps.hasFileDialog).
// 없는 곳에서는 화면이 이 기능을 아예 안 보여준다.

import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// SGF 파일 형식 필터
const XTypeGroup kSgfTypeGroup = XTypeGroup(
  label: 'SGF',
  extensions: <String>['sgf'],
);

/// 백업(JSON) 형식 필터 — 데이터 가져오기/내보내기 (체크리스트 D5)
const XTypeGroup kJsonTypeGroup = XTypeGroup(
  label: 'JSON',
  extensions: <String>['json'],
);

/// 파일 작업의 결과. 취소와 실패를 구별한다 —
/// 취소했는데 "실패했습니다" 가 낭독되면 사용자가 놀란다.
sealed class FileOutcome {
  const FileOutcome();
}

final class FileCancelled extends FileOutcome {
  const FileCancelled();
}

final class FileWritten extends FileOutcome {
  const FileWritten(this.path);
  final String path;
}

final class FileRead extends FileOutcome {
  const FileRead(this.contents, this.path);
  final String contents;
  final String path;
}

final class FileFailed extends FileOutcome {
  const FileFailed(this.reasonKey, {this.detail});

  /// i18n 키
  final String reasonKey;
  final String? detail;
}

/// 파일 시스템 접근을 한 곳에 모아 둔다. 테스트가 가짜를 끼울 수 있다.
abstract class SgfFileIo {
  Future<FileOutcome> save(String contents, {required String suggestedName});
  Future<FileOutcome> open();
}

class DesktopSgfFileIo implements SgfFileIo {
  const DesktopSgfFileIo({this.typeGroup = kSgfTypeGroup});

  /// 대화상자 파일 필터. 기본은 SGF, 백업은 [kJsonTypeGroup] 을 끼운다.
  final XTypeGroup typeGroup;

  @override
  Future<FileOutcome> save(String contents,
      {required String suggestedName}) async {
    try {
      final FileSaveLocation? loc = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );
      if (loc == null) return const FileCancelled();
      await File(loc.path).writeAsString(contents);
      return FileWritten(loc.path);
    } on FileSystemException catch (e) {
      return FileFailed('sgfWriteFailed', detail: e.osError?.message);
    }
  }

  @override
  Future<FileOutcome> open() async {
    try {
      final XFile? f =
          await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (f == null) return const FileCancelled();
      return FileRead(await f.readAsString(), f.path);
    } on FileSystemException catch (e) {
      return FileFailed('sgfReadFailed', detail: e.osError?.message);
    }
  }
}

/// 기보 파일 이름. 날짜는 호출자가 넘긴다 —
/// 순수 함수로 두어야 테스트가 시각에 흔들리지 않는다.
String sgfFileName(int lines, DateTime when) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'svil-baduk_${when.year}${two(when.month)}${two(when.day)}'
      '_${two(when.hour)}${two(when.minute)}_${lines}x$lines.sgf';
}
