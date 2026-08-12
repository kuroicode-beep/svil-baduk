// lib/application/app_container.dart — 손으로 만든 DI
//
// 하우스 관례(svil-task-monitor)를 따른다: 상태관리 패키지를 쓰지 않고
// ChangeNotifier + 컨테이너 하나로 조립한다. main() 에서 만들고 아래로 넘긴다.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/learn_progress_store.dart';
import '../data/db/settings_store.dart';
import '../data/platform/current_platform.dart';
import '../domain/learn/curriculum.dart';
import '../domain/platform_caps.dart';
import '../ui/theme/board_theme.dart';
import '../ui/theme/svil_theme.dart';

/// 시각·접근성 설정. 저시력 앱이라 이게 사실상 핵심 상태다.
class VisionController extends ChangeNotifier {
  VisionSettings _vision = const VisionSettings();
  BoardPaletteId _palette = BoardPaletteId.classic;
  AnnounceVerbosity _verbosity = AnnounceVerbosity.terse;

  VisionSettings get vision => _vision;
  BoardPalette get palette => BoardPalette.byId(_palette);
  BoardPaletteId get paletteId => _palette;
  AnnounceVerbosity get verbosity => _verbosity;

  void update(VisionSettings next) {
    if (next == _vision) return;
    _vision = next;
    notifyListeners();
  }

  void setContrast(ContrastProfile p) => update(_vision.copyWith(contrast: p));
  void setFocusRing(FocusRingColor c) => update(_vision.copyWith(focusRing: c));
  void setBaseFontSize(double s) => update(_vision.copyWith(baseFontSize: s));
  void setReduceMotion(bool v) => update(_vision.copyWith(reduceMotion: v));

  void setPalette(BoardPaletteId id) {
    if (id == _palette) return;
    _palette = id;
    notifyListeners();
  }

  void setVerbosity(AnnounceVerbosity v) {
    if (v == _verbosity) return;
    _verbosity = v;
    notifyListeners();
  }
}

/// 설정 한 벌 + 저장. 바뀌면 바로 디스크에 쓴다 —
/// 앱이 갑자기 닫혀도 설정이 날아가면 안 된다.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs, this._settings);

  static const String _key = 'svil-baduk-settings';

  final SharedPreferences _prefs;
  AppSettings _settings;

  AppSettings get settings => _settings;

  void update(AppSettings next) {
    if (next == _settings) return;
    _settings = next;
    unawaited(_prefs.setString(_key, settingsToString(next)));
    notifyListeners();
  }

  static AppSettings load(SharedPreferences prefs) =>
      settingsFromString(prefs.getString(_key));
}

/// 배우기 진행. 문제를 풀 때마다 저장한다.
class ProgressController extends ChangeNotifier {
  ProgressController(this._prefs, this._solved);

  final SharedPreferences _prefs;
  Set<String> _solved;

  Set<String> get solved => Set<String>.unmodifiable(_solved);

  void save(Set<String> next) {
    _solved = Set<String>.from(next);
    unawaited(_prefs.setString(kLearnProgressKey, encodeLearnProgress(_solved)));
    notifyListeners();
  }

  static Set<String> load(SharedPreferences prefs) =>
      decodeLearnProgress(prefs.getString(kLearnProgressKey));
}

class AppContainer {
  AppContainer._({
    required this.vision,
    required this.caps,
    required this.settings,
    required this.progress,
    required this.curriculum,
  });

  final VisionController vision;

  /// 이 기기에서 실제로 되는 것 — KataGo 노출 여부 등을 여기서 판단한다
  final PlatformCaps caps;

  final SettingsController settings;
  final ProgressController progress;
  final Curriculum curriculum;

  /// [prefs] 를 넘기면 그걸 쓴다. 테스트가 저장소를 직접 주고
  /// SharedPreferences 싱글턴을 건드리지 않게 하기 위한 것이다.
  static Future<AppContainer> create({SharedPreferences? prefs}) async {
    final PlatformCaps caps = detectCaps();
    final SharedPreferences store =
        prefs ?? await SharedPreferences.getInstance();
    final AppSettings loaded = SettingsController.load(store);

    final VisionController vision = VisionController()
      ..update(loaded.toVision(systemReduceMotion: false))
      ..setPalette(loaded.palette)
      ..setVerbosity(loaded.verbosity);

    return AppContainer._(
      vision: vision,
      caps: caps,
      settings: SettingsController(store, loaded),
      progress: ProgressController(store, ProgressController.load(store)),
      curriculum: Curriculum.parse(
          await rootBundle.loadString('assets/learn/curriculum.json')),
    );
  }

  Future<void> dispose() async {
    vision.dispose();
    settings.dispose();
    progress.dispose();
  }
}
