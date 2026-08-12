// test/lint/guardrails_test.dart — 설계 결정을 CI 가 강제한다
//
// 계획서의 체크리스트 A19·T6·T7·T8·V5 에 해당한다.
// 사람이 리뷰에서 잡는 대신 테스트가 잡는다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 주석을 지운다. 설명문에 쓴 예시가 위반으로 잡히면 안 된다
/// (실제로 board_announcer 의 "announce 는 deprecated" 주석이 걸렸다).
///
/// 줄 끝 앵커를 쓰지 않는 이유: 이 저장소는 CRLF 라서 캐리지 리턴 때문에
/// 줄 끝 매칭이 실패한다.
String stripComments(String src) {
  final String noBlock = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return noBlock.replaceAll(RegExp(r'^[ \t]*//[^\n]*', multiLine: true), '');
}

/// lib 아래 .dart 파일 전부 (자동 생성 제외)
List<File> _libFiles() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'))
      .toList();
}

String _code(File f) => stripComments(f.readAsStringSync());

void main() {
  test('주석 제거가 CRLF 파일에서도 동작한다', () {
    // 이 헬퍼가 조용히 실패하면 아래 가드레일이 전부 무력해진다
    expect(stripComments('// hi\r\ncode();\r\n').contains('hi'), isFalse);
    expect(stripComments('// hi\ncode();\n').contains('hi'), isFalse);
    expect(stripComments('/* block */code();').contains('block'), isFalse);
    expect(stripComments('code(); // tail\r\n').contains('code();'), isTrue);
  });

  test('A19 · Semantics(liveRegion:) 를 쓰지 않는다', () {
    // 엔진에서 Assertiveness.polite 로 하드코딩돼 있어 반칙 알림에 쓸 수 없다.
    final List<String> offenders = <String>[
      for (final File f in _libFiles())
        if (RegExp(r'liveRegion\s*:').hasMatch(_code(f))) f.path,
    ];
    expect(offenders, isEmpty,
        reason: 'liveRegion 은 polite 고정이라 오류 알림에 부적합합니다');
  });

  test('deprecated 된 announce 대신 sendAnnouncement 를 쓴다', () {
    final List<String> offenders = <String>[
      for (final File f in _libFiles())
        if (RegExp(r'SemanticsService\.announce\b').hasMatch(_code(f))) f.path,
    ];
    expect(offenders, isEmpty, reason: 'sendAnnouncement 를 쓰세요');
  });

  test('T8 · domain 은 package:flutter 를 import 하지 않는다', () {
    final List<String> offenders = <String>[
      for (final File f in _libFiles())
        if (f.path.contains('domain') &&
            RegExp(r"import\s+'package:flutter/").hasMatch(_code(f)))
          f.path,
    ];
    expect(offenders, isEmpty,
        reason: 'domain 은 순수 Dart 여야 테스트·재사용이 쉽습니다');
  });

  test('V5 · 색 리터럴은 테마 파일에만 있다', () {
    final List<String> offenders = <String>[];
    for (final File f in _libFiles()) {
      if (f.path.replaceAll(r'\', '/').contains('ui/theme/')) continue;
      for (final RegExpMatch m
          in RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').allMatches(_code(f))) {
        offenders.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(offenders, isEmpty, reason: 'SvilColors / BoardPalette 토큰을 참조하세요');
  });

  test('T6·T7 · 상태관리 패키지와 peerdart 를 쓰지 않는다', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final String banned in <String>[
      // 하우스 관례: ChangeNotifier + AppContainer
      'provider:',
      'riverpod',
      'flutter_bloc',
      'get_it',
      // 총 다운로드 426회, 자칭 알파, 23개월 정체
      'peerdart',
    ]) {
      expect(pubspec.contains(banned), isFalse, reason: '$banned 는 쓰지 않기로 했습니다');
    }
  });

  test('버전이 pubspec 과 version.dart 에서 일치한다', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String versionDart = File('lib/version.dart').readAsStringSync();
    final String? fromPubspec =
        RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true)
            .firstMatch(pubspec)
            ?.group(1);
    final String? fromDart =
        RegExp(r"appVersion\s*=\s*'([^']+)'").firstMatch(versionDart)?.group(1);
    expect(fromPubspec, isNotNull);
    expect(fromDart, equals(fromPubspec), reason: 'npm run version:sync 를 돌리세요');
  });

  test('한국어 로케일 빌드를 위한 /utf-8 이 CMake 에 있다', () {
    // 1단계 P2P 스파이크에서 flutter_webrtc 가 C4819 로 빌드 실패했다
    final String cmake = File('windows/CMakeLists.txt').readAsStringSync();
    expect(cmake.contains('/utf-8'), isTrue,
        reason: '코드페이지 949 에서 UTF-8 소스를 읽는 플러그인이 빌드에 실패합니다');
  });
}
