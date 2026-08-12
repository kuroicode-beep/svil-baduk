// test/domain/platform_caps_test.dart — 플랫폼별 능력 차이를 고정한다
import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/platform_caps.dart';

void main() {
  test('KataGo 는 데스크톱에서만 — 모바일은 Process 가 없고 신경망이 87MB', () {
    for (final AppPlatform p in <AppPlatform>[
      AppPlatform.windows,
      AppPlatform.macos,
      AppPlatform.linux,
    ]) {
      expect(PlatformCaps(p).canRunKataGo, isTrue, reason: p.name);
      expect(PlatformCaps(p).kataGoUnavailableReasonKey(), isNull, reason: p.name);
    }
    for (final AppPlatform p in <AppPlatform>[
      AppPlatform.android,
      AppPlatform.ios,
      AppPlatform.web,
    ]) {
      expect(PlatformCaps(p).canRunKataGo, isFalse, reason: p.name);
      // 버튼만 두고 실패시키지 않는다 — 이유를 보여준다
      expect(PlatformCaps(p).kataGoUnavailableReasonKey(), isNotNull,
          reason: p.name);
    }
  });

  test('OS 고대비는 iOS 만 보고한다 — 나머지는 인앱 프로파일이 유일한 수단', () {
    expect(PlatformCaps(AppPlatform.ios).reportsHighContrast, isTrue);
    for (final AppPlatform p in <AppPlatform>[
      AppPlatform.windows,
      AppPlatform.android,
      AppPlatform.web,
      AppPlatform.macos,
      AppPlatform.linux,
    ]) {
      expect(PlatformCaps(p).reportsHighContrast, isFalse, reason: p.name);
    }
  });

  test('안드로이드는 안내 이벤트를 폐기해 critical 경로 재검증이 필요하다', () {
    expect(PlatformCaps(AppPlatform.android).announceIsReliable, isFalse);
    expect(PlatformCaps(AppPlatform.windows).announceIsReliable, isTrue);
    expect(PlatformCaps(AppPlatform.ios).announceIsReliable, isTrue);
  });

  test('터치 기기는 확정 착수를 기본으로', () {
    expect(PlatformCaps(AppPlatform.android).prefersConfirmPlacement, isTrue);
    expect(PlatformCaps(AppPlatform.ios).prefersConfirmPlacement, isTrue);
    expect(PlatformCaps(AppPlatform.windows).prefersConfirmPlacement, isFalse);
  });

  test('창 제어·파일 대화상자는 데스크톱만', () {
    expect(PlatformCaps(AppPlatform.windows).canControlWindow, isTrue);
    expect(PlatformCaps(AppPlatform.android).canControlWindow, isFalse);
    expect(PlatformCaps(AppPlatform.windows).hasFileDialog, isTrue);
    expect(PlatformCaps(AppPlatform.web).hasFileDialog, isFalse);
  });

  test('모든 플랫폼이 분류된다 — 새 플랫폼이 조용히 빠지지 않게', () {
    for (final AppPlatform p in AppPlatform.values) {
      final PlatformCaps c = PlatformCaps(p);
      expect(c.isDesktop || c.isMobile || p == AppPlatform.web, isTrue,
          reason: '${p.name} 이 어느 분류에도 없습니다');
    }
  });
}
