// lib/domain/platform_caps.dart — 플랫폼별로 실제로 되는 것
//
// 기능을 조용히 실패시키지 않고 미리 숨기거나 설명한다.
// 특히 KataGo: 모바일에는 Process.start 가 없고 신경망이 87MB 라
// 아예 못 돌린다. 버튼만 두고 눌렀을 때 실패하면 사용자는 자기 잘못인 줄 안다.

/// 순수 Dart 로 유지하기 위해 값으로 받는다 (domain 은 flutter 를 import 하지 않는다)
enum AppPlatform { windows, macos, linux, android, ios, web }

class PlatformCaps {
  const PlatformCaps(this.platform);
  final AppPlatform platform;

  bool get isDesktop =>
      platform == AppPlatform.windows ||
      platform == AppPlatform.macos ||
      platform == AppPlatform.linux;

  bool get isMobile =>
      platform == AppPlatform.android || platform == AppPlatform.ios;

  /// 외부 프로세스를 띄울 수 있는가 — KataGo 의 전제
  bool get canRunKataGo => isDesktop;

  /// OS 가 고대비 선호를 알려주는가.
  /// Windows·웹은 영구히 false 라(실측) 인앱 프로파일이 유일한 수단이다.
  bool get reportsHighContrast => platform == AppPlatform.ios;

  /// OS 가 굵은 글자 선호를 알려주는가
  bool get reportsBoldText =>
      platform == AppPlatform.ios || platform == AppPlatform.android;

  /// 안드로이드는 접근성 안내 이벤트를 폐기했다.
  /// critical 경로가 TalkBack 에서 다르게 동작하므로 재검증이 필요하다.
  bool get announceIsReliable => platform != AppPlatform.android;

  /// 터치 기기에서는 오터치가 잦아 확정 착수를 기본으로 둔다.
  /// 19줄에서 50px 교차점은 폰에서 산술적으로 불가능하다 (50 × 19 = 950px).
  bool get prefersConfirmPlacement => isMobile;

  /// 창 크기·전체화면을 앱이 제어할 수 있는가
  bool get canControlWindow => isDesktop;

  /// 파일 저장 대화상자를 쓸 수 있는가 (SGF 내보내기)
  bool get hasFileDialog => isDesktop;

  /// KataGo 를 못 쓰는 이유 — UI 가 그대로 보여준다
  String? kataGoUnavailableReasonKey() =>
      canRunKataGo ? null : 'katagoMobileUnavailable';
}
