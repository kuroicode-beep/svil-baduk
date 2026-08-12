// lib/ui/theme/svil_theme.dart — SVIL 디자인 토큰 + 다크 테마
//
// 하우스 표준(svil-task-monitor)을 그대로 따르되, 저시력 전용 앱이라
// 대비 프로파일과 바둑판 팔레트를 추가로 얹는다.
//
// Windows 는 MediaQuery.highContrast 를 영구히 false 로 보고하고
// (실측 확인, iOS 전용 API), OS 고대비 모드는 Flutter 표면에 아무 영향이 없다.
// 따라서 여기 있는 인앱 프로파일이 대비를 조절하는 **유일한** 수단이다.

import 'package:flutter/material.dart';

/// SVIL 색상 토큰 — 하드코딩 금지, 반드시 이 토큰을 참조할 것.
abstract final class SvilColors {
  static const bg = Color(0xFF0D0D12);
  static const surface = Color(0xFF16161D);
  static const surface2 = Color(0xFF1F1F2A);
  static const surfaceBox = Color(0xFF1B1B20);
  static const border = Color(0xFF3A3A48);
  static const borderStrong = Color(0xFF6B6B82);
  static const text = Color(0xFFF5F5F7);
  static const textSub = Color(0xFFC9C9D4);
  static const accent = Color(0xFF7EC8FF);
  static const accentStrong = Color(0xFFB3DDFF);
  static const accentMax = Color(0xFFD6ECFF);
  static const positive = Color(0xFF7EE2A8);
  static const warning = Color(0xFFFFD479);
  static const negative = Color(0xFFFF9B9B);

  /// 하우스 기본 포커스 색
  static const focus = Color(0xFFFFD479);

  /// 최대 대비 포커스 — 저시력 사용자가 선택할 수 있게 별도 제공.
  /// (React 판은 이 색을 기본으로 썼다)
  static const focusPure = Color(0xFFFFFF00);
}

const String kFontFamily = 'KyoboHandwriting2019';
const List<String> kFontFallback = <String>['Malgun Gothic', 'sans-serif'];

/// 숫자·좌표·타임스탬프·버전 — Consolas 모노스페이스.
/// 좌표에서 0/O, 1/I 를 혼동하지 않게 하는 것이 목적이다.
TextStyle monoStyle({
  double size = 15,
  Color color = SvilColors.textSub,
  FontWeight weight = FontWeight.w400,
}) =>
    TextStyle(
      fontFamily: 'Consolas',
      fontFamilyFallback: const <String>[kFontFamily, ...kFontFallback],
      fontSize: size,
      color: color,
      fontWeight: weight,
    );

/// 낭독 상세도 — 좌표만 읽을지, 주변 정보까지 읽을지.
/// 저시력·스크린리더 사용자가 발화 길이를 직접 고를 수 있어야 한다.
enum AnnounceVerbosity { terse, full }

/// 대비 프로파일 — OS 고대비를 못 읽으므로 앱이 직접 제공한다
// 라벨은 i18n 에서 온다. enum 에 한국어를 박아 두면 다른 언어에서
// 조용히 한국어가 새어 나온다 (하드코딩 문자열 0 규칙).
enum ContrastProfile { standard, high, maximum }

/// 포커스 링 색 선택
enum FocusRingColor {
  amber('호박색'),
  pureYellow('순노랑 (최대 대비)');

  const FocusRingColor(this.label);
  final String label;

  Color get color =>
      this == FocusRingColor.amber ? SvilColors.focus : SvilColors.focusPure;
}

/// 시각 설정 묶음 — 테마와 바둑판이 함께 참조한다
class VisionSettings {
  const VisionSettings({
    this.contrast = ContrastProfile.high,
    this.focusRing = FocusRingColor.amber,
    this.baseFontSize = 18,
    this.reduceMotion = false,
  });

  final ContrastProfile contrast;
  final FocusRingColor focusRing;

  /// 하우스 기준 본문 18px
  final double baseFontSize;
  final bool reduceMotion;

  Color get focusColor => focusRing.color;

  /// 프로파일에 따라 본문·테두리를 더 밝게 민다
  Color get textColor => switch (contrast) {
        ContrastProfile.standard => SvilColors.text,
        ContrastProfile.high => SvilColors.text,
        ContrastProfile.maximum => const Color(0xFFFFFFFF),
      };

  Color get subTextColor => switch (contrast) {
        ContrastProfile.standard => SvilColors.textSub,
        ContrastProfile.high => SvilColors.textSub,
        // 최대 대비에서는 보조 텍스트도 본문 수준으로 올린다
        ContrastProfile.maximum => const Color(0xFFF0F0F5),
      };

  Color get backgroundColor => switch (contrast) {
        ContrastProfile.standard => SvilColors.bg,
        ContrastProfile.high => SvilColors.bg,
        ContrastProfile.maximum => const Color(0xFF000000),
      };

  /// 구조를 전달하는 테두리는 표준 프로파일에서도 3:1 을 지킨다.
  /// (하우스의 border #3A3A48 은 1.5:1 대의 장식용 구분선이라
  ///  저시력 앱의 기능적 테두리로는 쓸 수 없다)
  Color get borderColor => switch (contrast) {
        ContrastProfile.standard => SvilColors.borderStrong,
        ContrastProfile.high => const Color(0xFF8A929A),
        ContrastProfile.maximum => const Color(0xFFFFFFFF),
      };

  VisionSettings copyWith({
    ContrastProfile? contrast,
    FocusRingColor? focusRing,
    double? baseFontSize,
    bool? reduceMotion,
  }) =>
      VisionSettings(
        contrast: contrast ?? this.contrast,
        focusRing: focusRing ?? this.focusRing,
        baseFontSize: baseFontSize ?? this.baseFontSize,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );
}

/// 터치·클릭 타깃 최소 크기. 19줄 판의 교차점에는 적용할 수 없다
/// (50 × 19 = 950px 라 폰에서 산술적으로 불가능) — 그래서 확정 버튼을 크게 만든다.
const double kTouchMin = 48;
const double kTouchLarge = 56;
const double kListItemMin = 60;

ThemeData buildBadukTheme(VisionSettings v) {
  final double base = v.baseFontSize;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: v.backgroundColor,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    colorScheme: ColorScheme.dark(
      surface: SvilColors.surface,
      primary: SvilColors.accent,
      onPrimary: SvilColors.bg,
      secondary: SvilColors.accentStrong,
      error: SvilColors.negative,
      outline: v.borderColor,
    ),
    // 합성 볼드 금지 — 위계는 크기와 색으로 만든다
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: base, height: 1.6, color: v.textColor),
      bodyMedium: TextStyle(fontSize: base, height: 1.6, color: v.textColor),
      bodySmall: TextStyle(fontSize: base * 0.89, height: 1.5, color: v.subTextColor),
      titleLarge: TextStyle(fontSize: base * 1.78, color: v.textColor),
      titleMedium: TextStyle(fontSize: base * 1.33, color: v.textColor),
      labelLarge: TextStyle(fontSize: base, color: v.textColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SvilColors.surface2,
      labelStyle: TextStyle(color: v.subTextColor, fontSize: base),
      hintStyle: TextStyle(color: v.subTextColor, fontSize: base),
      helperStyle: TextStyle(color: v.subTextColor, fontSize: base * 0.89),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: v.borderColor, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: v.focusColor, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kTouchMin, kTouchMin),
        textStyle: TextStyle(fontSize: base, fontFamily: kFontFamily),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kTouchMin, kTouchMin),
        side: BorderSide(color: v.borderColor, width: 2),
        textStyle: TextStyle(fontSize: base, fontFamily: kFontFamily),
      ),
    ),
    dividerTheme: DividerThemeData(color: v.borderColor),
  );
}
