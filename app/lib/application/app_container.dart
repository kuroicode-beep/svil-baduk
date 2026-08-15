// lib/application/app_container.dart — 손으로 만든 DI
//
// 하우스 관례(svil-task-monitor)를 따른다: 상태관리 패키지를 쓰지 않고
// ChangeNotifier + 컨테이너 하나로 조립한다. main() 에서 만들고 아래로 넘긴다.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/learn_progress_store.dart';
import '../domain/backup.dart';
import '../domain/profile/profile.dart';
import '../data/db/settings_store.dart';
import '../data/p2p/webrtc_endpoint.dart';
import '../data/platform/current_platform.dart';
import '../domain/learn/curriculum.dart';
import '../domain/p2p/transport.dart';
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

/// 플레이어 프로필 — 별명·급수·레벨·경험치·전적. 바뀌면 바로 저장한다.
class ProfileController extends ChangeNotifier {
  ProfileController(this._prefs, this._profile);

  final SharedPreferences _prefs;
  Profile _profile;

  Profile get profile => _profile;

  void update(Profile next) {
    _profile = next;
    unawaited(_prefs.setString(kProfileKey, encodeProfile(next)));
    notifyListeners();
  }

  void setName(String name) {
    update(_profile.copyWith(
      name: name.trim(),
      createdAt: _profile.createdAt ?? DateTime.now().toIso8601String(),
    ));
  }

  /// 대국 결과 반영. 얼마나 얻었는지 돌려줘 화면이 낭독할 수 있게 한다.
  GameRecordResult record(GameRecordInput input) {
    final GameRecordResult r = recordSoloResult(_profile, input);
    update(r.profile);
    return r;
  }

  static Profile load(SharedPreferences prefs) =>
      decodeProfile(prefs.getString(kProfileKey));
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
    required this.profile,
    required this.curriculum,
    required this.makeEndpoint,
    required this.prefs,
  });

  /// 백업 가져오기/내보내기가 저장소 원문을 직접 읽고 쓴다
  final SharedPreferences prefs;

  final VisionController vision;

  /// 이 기기에서 실제로 되는 것 — KataGo 노출 여부 등을 여기서 판단한다
  final PlatformCaps caps;

  final SettingsController settings;
  final ProgressController progress;
  final ProfileController profile;
  final Curriculum curriculum;

  /// P2P 전송 팩토리. 테스트가 가짜를 끼운다 —
  /// 위젯 테스트에서 실 WebSocket 이 열리면 FakeAsync 가 멈춘다.
  final P2PEndpoint Function() makeEndpoint;

  /// [prefs] 를 넘기면 그걸 쓴다. 테스트가 저장소를 직접 주고
  /// SharedPreferences 싱글턴을 건드리지 않게 하기 위한 것이다.
  static Future<AppContainer> create({
    SharedPreferences? prefs,
    P2PEndpoint Function()? makeEndpoint,
  }) async {
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
      profile: ProfileController(store, ProfileController.load(store)),
      curriculum: Curriculum.parse(
          await rootBundle.loadString('assets/learn/curriculum.json')),
      makeEndpoint: makeEndpoint ?? WebRtcEndpoint.new,
      prefs: store,
    );
  }

  /// React 판(또는 다른 기기의 Flutter 판) 백업을 복원한다 (체크리스트 D5).
  /// 성공 시 컨트롤러들이 새 값으로 갱신돼 화면에 즉시 반영된다.
  /// 반환: (i18n 키, 되돌린 항목 수) — 키의 {n} 을 화면이 채운다.
  Future<(String, int)> importBackup(String text) async {
    final BackupResult r = decodeBackup(text);
    if (r is BackupFail) return (r.reasonKey, 0);
    final BackupOk ok = r as BackupOk;

    for (final MapEntry<String, String> e in ok.values.entries) {
      await prefs.setString(e.key, e.value);
    }
    // 각 로더가 검증·마이그레이션한다 — 백업 형식 자체는 신뢰하지 않는다
    final AppSettings loaded = SettingsController.load(prefs);
    settings.update(loaded);
    vision
      ..update(loaded.toVision(systemReduceMotion: false))
      ..setPalette(loaded.palette)
      ..setVerbosity(loaded.verbosity);
    profile.update(ProfileController.load(prefs));
    progress.save(ProgressController.load(prefs));
    return ('importDone', ok.values.length);
  }

  /// 현재 데이터를 React restoreBackup 이 읽을 수 있는 형식으로 만든다
  String exportBackup({required String appVersion}) {
    final Map<String, String> stored = <String, String>{};
    for (final String key in kBackupKeys) {
      final String? v = prefs.getString(key);
      if (v != null) stored[key] = v;
    }
    return encodeBackup(
      appVersion: appVersion,
      savedAt: DateTime.now().toIso8601String(),
      storedValues: stored,
    );
  }

  Future<void> dispose() async {
    vision.dispose();
    settings.dispose();
    progress.dispose();
    profile.dispose();
  }
}
