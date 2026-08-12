// lib/data/db/settings_store.dart — 설정 저장·마이그레이션
//
// React 판 src/settings/store.ts 의 스키마와 마이그레이션 규칙을 그대로 옮겼다.
// 백업 JSON(내보내기/가져오기)이 양쪽에서 호환되어야 하므로 키 이름과
// 값 문자열을 바꾸지 않는다.

import 'dart:convert';

import '../../domain/ai/ranks.dart';
import '../../domain/engine/types.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/board_theme.dart';
import '../../ui/theme/svil_theme.dart';

/// 저장 스키마 버전. 구조가 바뀌면 올리고 migrate 에 분기를 추가한다.
const int settingsVersion = 1;

const String settingsKey = 'svil-baduk-settings';

enum GoRules { japanese, chinese }

enum BoardScale { small, medium, large }

enum LineWeight { thin, normal, thick }

enum CoordMode { auto, on, off }

enum PlaceMode { direct, confirm }

/// 혼자 두기(양쪽 다 사람) / 내장 AI / KataGo
enum OpponentKind { none, builtin, katago }

/// 'system' 은 OS 설정을 그때그때 따른다.
/// 한 번만 시딩하면 나중에 OS 에서 켠 사용자에게 영영 반영되지 않는다.
enum ReduceMotionSetting { system, on, off }

class AppSettings {
  const AppSettings({
    this.lang = Lang.ko,
    this.fontSize = 18,
    this.contrast = ContrastProfile.high,
    this.focusRing = FocusRingColor.amber,
    this.palette = BoardPaletteId.classic,
    this.blinkIntersections = true,
    this.reduceMotion = ReduceMotionSetting.system,
    this.moveSound = true,
    this.boardScale = BoardScale.medium,
    this.lineWeight = LineWeight.normal,
    this.goRules = GoRules.japanese,
    this.coordMode = CoordMode.auto,
    this.placeMode = PlaceMode.direct,
    this.verbosity = AnnounceVerbosity.terse,
    this.katagoExe = '',
    this.katagoModel = '',
    this.katagoConfig = '',
    this.katagoAutoStart = true,
    this.opponent = OpponentKind.builtin,
    this.rankId = kDefaultRank,
    this.boardSize = BoardSize.s19,
  });

  final Lang lang;
  final double fontSize;
  final ContrastProfile contrast;
  final FocusRingColor focusRing;
  final BoardPaletteId palette;
  final bool blinkIntersections;
  final ReduceMotionSetting reduceMotion;
  final bool moveSound;
  final BoardScale boardScale;
  final LineWeight lineWeight;
  final GoRules goRules;
  final CoordMode coordMode;
  final PlaceMode placeMode;
  final AnnounceVerbosity verbosity;
  final String katagoExe;
  final String katagoModel;
  final String katagoConfig;
  final bool katagoAutoStart;
  final OpponentKind opponent;

  /// ai/ranks.dart 의 id. 저장값이 손상돼도 getRank 가 기본값으로 떨어진다.
  final String rankId;

  final BoardSize boardSize;

  VisionSettings toVision({required bool systemReduceMotion}) => VisionSettings(
        contrast: contrast,
        focusRing: focusRing,
        baseFontSize: fontSize,
        reduceMotion: switch (reduceMotion) {
          ReduceMotionSetting.on => true,
          ReduceMotionSetting.off => false,
          ReduceMotionSetting.system => systemReduceMotion,
        },
      );

  AppSettings copyWith({
    Lang? lang,
    double? fontSize,
    ContrastProfile? contrast,
    FocusRingColor? focusRing,
    BoardPaletteId? palette,
    bool? blinkIntersections,
    ReduceMotionSetting? reduceMotion,
    bool? moveSound,
    BoardScale? boardScale,
    LineWeight? lineWeight,
    GoRules? goRules,
    CoordMode? coordMode,
    PlaceMode? placeMode,
    AnnounceVerbosity? verbosity,
    String? katagoExe,
    String? katagoModel,
    String? katagoConfig,
    bool? katagoAutoStart,
    OpponentKind? opponent,
    String? rankId,
    BoardSize? boardSize,
  }) =>
      AppSettings(
        lang: lang ?? this.lang,
        fontSize: fontSize ?? this.fontSize,
        contrast: contrast ?? this.contrast,
        focusRing: focusRing ?? this.focusRing,
        palette: palette ?? this.palette,
        blinkIntersections: blinkIntersections ?? this.blinkIntersections,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        moveSound: moveSound ?? this.moveSound,
        boardScale: boardScale ?? this.boardScale,
        lineWeight: lineWeight ?? this.lineWeight,
        goRules: goRules ?? this.goRules,
        coordMode: coordMode ?? this.coordMode,
        placeMode: placeMode ?? this.placeMode,
        verbosity: verbosity ?? this.verbosity,
        katagoExe: katagoExe ?? this.katagoExe,
        katagoModel: katagoModel ?? this.katagoModel,
        katagoConfig: katagoConfig ?? this.katagoConfig,
        katagoAutoStart: katagoAutoStart ?? this.katagoAutoStart,
        opponent: opponent ?? this.opponent,
        rankId: rankId ?? this.rankId,
        boardSize: boardSize ?? this.boardSize,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': settingsVersion,
        'lang': lang.code,
        'fontSize': fontSize,
        'contrast': contrast.name,
        'focusRing': focusRing.name,
        'palette': palette.name,
        'blinkIntersections': blinkIntersections,
        'reduceMotion': switch (reduceMotion) {
          ReduceMotionSetting.system => 'system',
          ReduceMotionSetting.on => true,
          ReduceMotionSetting.off => false,
        },
        'moveSound': moveSound,
        'boardScale': boardScale.name,
        'lineWeight': lineWeight.name,
        'goRules': goRules.name,
        'boardCoords': coordMode.name,
        'placeMode': placeMode.name,
        'verbosity': verbosity.name,
        'katagoExe': katagoExe,
        'katagoModel': katagoModel,
        'katagoConfig': katagoConfig,
        'katagoAutoStart': katagoAutoStart,
        'opponent': opponent.name,
        'rankId': rankId,
        'boardSize': boardSize.lines,
      };
}

T _enumOr<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final T v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

/// 저장값을 현재 스키마로 올린다.
/// v 가 없으면 0.8.x 이하(버전 필드 없음)로 보고 v1 로 승격한다.
AppSettings migrateSettings(Object? raw) {
  const AppSettings base = AppSettings();
  if (raw is! Map) return base;
  final Map<String, dynamic> m = raw.cast<String, dynamic>();

  // v0: reduceMotion 이 boolean 뿐이었다. 명시적으로 켠 값만 유지하고,
  // 꺼둔(=기본값) 사용자는 OS 설정을 따르도록 'system' 으로 올린다.
  final Object? rm = m['reduceMotion'];
  final ReduceMotionSetting reduceMotion = switch (rm) {
    true => ReduceMotionSetting.on,
    'system' => ReduceMotionSetting.system,
    false when m['v'] != null => ReduceMotionSetting.off,
    _ => ReduceMotionSetting.system,
  };

  final Object? fs = m['fontSize'];
  final double fontSize = switch (fs) {
    // React 판은 small/medium/large 문자열이었다
    'small' => 16,
    'medium' => 18,
    'large' => 20,
    final num n when n >= 12 && n <= 40 => n.toDouble(),
    _ => base.fontSize,
  };

  return AppSettings(
    lang: m['lang'] is String ? Lang.fromCode(m['lang'] as String) : base.lang,
    fontSize: fontSize,
    contrast: _enumOr(ContrastProfile.values, m['contrast'], base.contrast),
    focusRing: _enumOr(FocusRingColor.values, m['focusRing'], base.focusRing),
    palette: _enumOr(BoardPaletteId.values, m['palette'], base.palette),
    blinkIntersections: m['blinkIntersections'] as bool? ?? base.blinkIntersections,
    reduceMotion: reduceMotion,
    moveSound: m['moveSound'] as bool? ?? base.moveSound,
    boardScale: _enumOr(BoardScale.values, m['boardScale'], base.boardScale),
    lineWeight: _enumOr(LineWeight.values, m['lineWeight'], base.lineWeight),
    goRules: _enumOr(GoRules.values, m['goRules'], base.goRules),
    coordMode: _enumOr(CoordMode.values, m['boardCoords'], base.coordMode),
    placeMode: _enumOr(PlaceMode.values, m['placeMode'], base.placeMode),
    verbosity: _enumOr(AnnounceVerbosity.values, m['verbosity'], base.verbosity),
    katagoExe: m['katagoExe'] as String? ?? base.katagoExe,
    katagoModel: m['katagoModel'] as String? ?? base.katagoModel,
    katagoConfig: m['katagoConfig'] as String? ?? base.katagoConfig,
    katagoAutoStart: m['katagoAutoStart'] as bool? ?? base.katagoAutoStart,
    opponent: _enumOr(OpponentKind.values, m['opponent'], base.opponent),
    // 없는 난이도가 저장돼 있어도 getRank 가 기본값을 준다
    rankId: m['rankId'] is String ? m['rankId'] as String : base.rankId,
    boardSize: switch (m['boardSize']) {
      9 => BoardSize.s9,
      13 => BoardSize.s13,
      19 => BoardSize.s19,
      _ => base.boardSize,
    },
  );
}

AppSettings settingsFromString(String? json) {
  if (json == null || json.isEmpty) return const AppSettings();
  try {
    return migrateSettings(jsonDecode(json));
  } catch (_) {
    return const AppSettings();
  }
}

String settingsToString(AppSettings s) => jsonEncode(s.toJson());
