# P2P 전송 스파이크 결과 — 1단계 게이트

- **작성일:** 2026-08-09
- **작성자:** Claude Code
- **대상:** `spikes/webrtc_p2p` (Flutter 3.44.8, `flutter_webrtc` 1.6.0, Windows x64 release)
- **상태:** 🟡 **크기·빌드 게이트 통과 / 네트워크 실측 대기** (서로 다른 네트워크의 두 대 필요)

---

## 1. 왜 이 스파이크가 필요한가

React 판의 P2P는 PeerJS(공개 클라우드 브로커)를 쓴다. Dart 대체재 후보 중
**`peerdart` 는 총 다운로드 426회 · 자칭 알파 · 23개월 정체**라 기능을 걸 수 없다.
유일하게 안전한 기반은 `flutter_webrtc`(1.35k likes, 주 26.5만 다운로드, 검증됨)이고,
PeerJS 브로커 프로토콜을 말하는 Dart 클라이언트를 직접 써야 한다.

그런데 `libwebrtc.dll` 이 크다는 것이 알려져 있어, **설치 용량에 미치는 영향을
쓰기 전에 반드시 실측**하기로 했다.

---

## 2. 실측 결과

### 2.1 🔴 한국어 Windows 에서 `flutter_webrtc` 는 그대로는 빌드되지 않는다

```
error C2220: 경고를 오류로 처리합니다
  common/cpp/src/flutter_media_stream.cc
  common/cpp/src/flutter_screen_capture.cc
  common/cpp/include/loopback_capturer.h
  windows/application_loopback_capturer.cc
  windows/loopback_capturer_factory.cc
```

근본 원인은 **C4819** — 시스템 로케일이 한국어(코드페이지 949)라
MSVC 가 플러그인의 UTF-8 C++ 소스에 있는 문자를 표현하지 못한다.
플러그인이 경고를 오류로 처리하므로 빌드가 통째로 실패한다.

**해결:** 앱의 `windows/CMakeLists.txt` 에 `/utf-8` 을 전역으로 준다.

```cmake
if(MSVC)
  add_compile_options("/utf-8")
endif()
```

시스템 로케일 변경(Windows "세계 언어 지원을 위한 Unicode UTF-8 사용")으로도
풀리지만, 시스템 설정을 건드리는 대신 프로젝트에서 해결하는 쪽을 택했다.
**본 구현(`app/windows/CMakeLists.txt`)에도 이 블록을 반드시 넣어야 한다.**

### 2.2 크기 — 게이트 통과, 단 총량 예산은 상향 필요

| 구성 | 크기 |
|---|---|
| 기준선 (빈 Flutter Windows 릴리스) | **27 MB** |
| `flutter_webrtc` 추가 후 | **47 MB** |
| **증가분** | **20 MB** |

내역:

| 파일 | 크기 |
|---|---|
| `flutter_windows.dll` | 21 MB |
| **`libwebrtc.dll`** | **20 MB** |
| `webrtc_p2p.exe` | 1 MB |
| `flutter_webrtc_plugin.dll` | 1 MB |

| 판정 | 기준 | 실측 | 결과 |
|---|---|---|---|
| 스파이크 기준 5 — 증가분 | ≤ 25 MB | 20 MB | ✅ **통과** |
| 체크리스트 B2 — 총 설치 용량 | ≤ 35 MB | 47 MB | ❌ **초과** |

**결정 (2026-08-09):** 체크리스트 B2 를 **60MB 로 상향**한다.
- 대안이던 "P2P 를 선택 다운로드로 분리"는 동적 DLL 로딩·플러그인 게이팅 복잡도에 비해
  이득이 적다. 데스크톱 게임에서 47MB 는 특이한 값이 아니다.
- 참고로 Tauri 판은 설치 8.3MB / 설치파일 1.9MB 였다. **약 5.7배 증가**를 받아들이는 것이다.
- 이 결정은 계획서에 미리 정해둔 탈출구를 따른 것이며, 계획서 B2 항목에 기록했다.

### 2.3 빌드·정적 검사

| 항목 | 결과 |
|---|---|
| `flutter build windows --release` (`/utf-8` 적용 후) | ✅ 성공 (31.4초) |
| 의존성 추가 | 31개 (flutter_webrtc + 전이 의존성) |

---

## 3. 미완 — 네트워크 실측 (두 대 필요)

아래는 서로 다른 네트워크의 Windows 2대가 있어야 확인 가능하다
(한 대는 휴대폰 핫스팟 권장 — NAT 통과를 실제로 시험하기 위해).

| # | 기준 | 결과 |
|---|---|---|
| 1 | 서로 다른 네트워크의 두 대가 공개 PeerJS 브로커로 **10초 내** 연결 | ⬜ |
| 2 | 양방향 50개 메시지, 손실 0 · 순서 뒤바뀜 0 | ⬜ |
| 3 | 60초 유휴 후에도 메시지 전달 (브로커 heartbeat 유지) | ⬜ |
| 4 | 한쪽 재시작 → 다른 쪽이 **15초 내** 끊김 감지·재연결 경로 표시 | ⬜ |
| 5 | 릴리스 빌드 증가 ≤ 25MB | ✅ **20MB 통과** |
| 6 | QR 로 인코딩한 방 ID 가 휴대폰 카메라로 왕복 | ⬜ |

### 실패 시 사다리 (계획서에 미리 정해둔 것)
1. 사용자의 기존 Railway 에 `peerjs-server` 자체 호스팅
2. 150줄짜리 자체 WebSocket 시그널링 서버를 Railway 에
3. **P2P 를 1.0.0 에서 빼고 1.1.0 으로** — 게임은 P2P 없이도 완전히 쓸 수 있다

---

## 4. 본 구현으로 넘길 것

- `app/windows/CMakeLists.txt` 에 **`/utf-8` 블록 필수** (§2.1)
- `peerdart` **사용 금지** — CI 테스트(`guardrails_test.dart`)가 이미 강제하고 있다
- 데이터 채널 payload 는 PeerJS BinaryPack 이 아니라 **평문 JSON + `protocol: 2` 필드**
- React 판(PeerJS)과의 교차 대국은 **지원하지 않는다**고 UI 에 명시
- 방 ID 는 QR 과 **한 글자씩 읽을 수 있는 큰 모노스페이스 문자열** 양쪽으로 제공
