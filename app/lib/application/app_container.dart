// lib/application/app_container.dart — 손으로 만든 DI
//
// 하우스 관례(svil-task-monitor)를 따른다: 상태관리 패키지를 쓰지 않고
// ChangeNotifier + 컨테이너 하나로 조립한다. main() 에서 만들고 아래로 넘긴다.

import 'package:flutter/foundation.dart';

import '../data/platform/current_platform.dart';
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

class AppContainer {
  AppContainer._(this.vision, this.caps);

  final VisionController vision;

  /// 이 기기에서 실제로 되는 것 — KataGo 노출 여부 등을 여기서 판단한다
  final PlatformCaps caps;

  static Future<AppContainer> create() async {
    final PlatformCaps caps = detectCaps();
    final VisionController vision = VisionController();
    // 터치 기기는 오터치가 잦아 확정 착수를 기본으로 둔다
    if (caps.prefersConfirmPlacement) vision.setVerbosity(AnnounceVerbosity.terse);
    return AppContainer._(vision, caps);
  }

  Future<void> dispose() async {
    vision.dispose();
  }
}
