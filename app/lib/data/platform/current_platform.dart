// lib/data/platform/current_platform.dart — 실행 중인 플랫폼 감지
//
// domain/platform_caps.dart 는 순수 Dart 라 플랫폼을 값으로 받는다.
// 실제 감지는 여기서 한 번만 하고 AppContainer 가 들고 다닌다.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/platform_caps.dart';

AppPlatform detectPlatform() {
  if (kIsWeb) return AppPlatform.web;
  if (Platform.isWindows) return AppPlatform.windows;
  if (Platform.isMacOS) return AppPlatform.macos;
  if (Platform.isLinux) return AppPlatform.linux;
  if (Platform.isAndroid) return AppPlatform.android;
  if (Platform.isIOS) return AppPlatform.ios;
  // 모르는 플랫폼은 가장 보수적으로 — 데스크톱 전용 기능을 켜지 않는다
  return AppPlatform.web;
}

PlatformCaps detectCaps() => PlatformCaps(detectPlatform());
