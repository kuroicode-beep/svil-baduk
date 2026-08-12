// test/lint/guardrails_test.dart — 설계 결정을 CI 가 강제한다
//
// 계획서의 체크리스트 A19·T6·T7·T8·V5 에 해당한다.
// 사람이 리뷰에서 잡는 대신 테스트가 잡는다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib 아래 .dart 파일 전부 (자동 생성 제외)
List<File> _libFiles() {
  final Directory dir = Directory('lib');
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'))
      .toList();
}

void main() {
  test('A19 · Semantics(liveRegion:) 를 쓰지 않는다', () {
    // Flutter 엔진에서 liveRegion 은 Assertiveness.polite 로 하드코딩돼 있어
    // 반칙·오류 알림에 쓸 수 없다. 대신 sendAnnouncement(assertive) 를 쓴다.
    final List<String> offenders = <String>[];
    for (final File f in _libFiles()) {
      final String text = f.readAsStringSync();
      if (RegExp(r'liveRegion\s*:').hasMatch(text)) offenders.add(f.path);
    }
    expect(offenders, isEmpty,
        reason: 'liveRegion 은 polite 고정이라 오류 알림에 부적합합니다');
  });

  test('deprecated 된 SemanticsService.announce 를 쓰지 않는다', () {
    // 3.35 이후 deprecated. sendAnnouncement(FlutterView, ...) 를 쓴다.
    final List<String> offenders = <String>[];
    for (final File f in _libFiles()) {
      final String text = f.readAsStringSync();
      if (RegExp(r'SemanticsService\.announce\b').hasMatch(text)) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: 'sendAnnouncement 를 쓰세요');
  });

  test('T8 · domain 은 package:flutter 를 import 하지 않는다', () {
    final List<String> offenders = <String>[];
    for (final File f in _libFiles()) {
      if (!f.path.contains('domain')) continue;
      final String text = f.readAsStringSync();
      if (RegExp(r"import\s+'package:flutter/").hasMatch(text)) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'domain 은 순수 Dart 여야 테스트·재사용이 쉽습니다');
  });

  test('V5 · 색 리터럴은 테마 파일에만 있다', () {
    final List<String> offenders = <String>[];
    for (final File f in _libFiles()) {
      final String p = f.path.replaceAll(r'\', '/');
      if (p.contains('ui/theme/')) continue;
      final String text = f.readAsStringSync();
      for (final RegExpMatch m in RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').allMatches(text)) {
        offenders.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'SvilColors / BoardPalette 토큰을 참조하세요');
  });

  test('T6·T7 · 상태관리 패키지와 peerdart 를 쓰지 않는다', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    // 하우스 관례: ChangeNotifier + AppContainer
    for (final String banned in <String>[
      'provider:',
      'riverpod',
      'flutter_bloc',
      'get_it',
      'get:',
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
        RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true).firstMatch(pubspec)?.group(1);
    final String? fromDart =
        RegExp(r"appVersion\s*=\s*'([^']+)'").firstMatch(versionDart)?.group(1);
    expect(fromPubspec, isNotNull);
    expect(fromDart, equals(fromPubspec),
        reason: 'npm run version:sync 를 돌리세요');
  });
}
