# 접근성 스파이크 결과 — 1단계 게이트

- **작성일:** 2026-08-09
- **작성자:** Claude Code
- **대상:** `spikes/board_a11y` (Flutter 3.44.8 stable, Dart 3.12.2, Windows x64 release)
- **상태:** 🟡 **자동 측정 완료 / 스크린리더 실측 대기** — 아래 §3은 사람이 수행해야 함

---

## 1. 배경

바둑판의 현재(React) 접근성 모델은 `role="grid"` + `aria-rowindex/colindex` + `aria-activedescendant`다.
Flutter 엔진 소스 확인 결과 이 모델은 **어떤 Flutter 플랫폼에도 존재하지 않는다**:

- `SemanticsRole` enum(33개)에 `grid`/`gridcell` 없음
- `aria-activedescendant` 상당 개념 없음
- Windows는 MSAA(`IAccessible`)만 사용, UIA는 `FLUTTER_ENGINE_USE_UIA` 뒤로 컴파일 아웃
  (#94782, 2021-12 open) → 스크린리더의 격자 탐색(UIA `GridPattern`)에 좌표를 전달할 통로 없음

그래서 모델을 뒤집었다: **판 = 값을 가진 컨트롤 하나 + 명령어 언어**.
이 스파이크는 그 모델이 실제로 통하는지를 확인하기 위한 것이다.

---

## 2. 자동 측정 결과 (완료)

### 2.1 플랫폼 접근성 기능 보고값

Windows 11 · Flutter 3.44.8 · release 빌드 · **스크린리더 미실행 상태**에서 앱이 직접 출력:

```
accessibleNavigation : false      <- 스크린리더 미실행이므로 정상
supportsAnnounce     : true
highContrast         : false
disableAnimations    : false
boldText             : false
invertColors         : false
semanticsEnabled     : true
```

**해석 — 계획에 영향을 주는 두 가지:**

| 항목 | 결과 | 의미 |
|---|---|---|
| `semanticsEnabled` | ✅ **true (기본값)** | **Windows 데스크톱은 시맨틱스가 처음부터 켜져 있다.** 웹의 "1×1px Enable accessibility 버튼 뒤에 꺼져 있음" 문제가 데스크톱에는 **없다**. 웹 대신 데스크톱을 먼저 하기로 한 결정을 뒷받침한다. |
| `supportsAnnounce` | ✅ **true** | Windows에서 `sendAnnouncement` 경로가 살아 있다. 사건·오류 안내를 이 경로로 보낼 수 있다. |
| `highContrast` | ⚠️ false | 예상대로 Windows 고대비를 못 읽는다. **인앱 대비 프로파일이 유일한 수단**임이 확인됨. |
| `boldText` | ⚠️ false | 예상대로 iOS/Android 전용. |

### 2.2 API 변경 — 계획 수정 필요

**`SemanticsService.announce`는 Flutter 3.35 이후 deprecated**다. (조사 단계에서 못 잡은 항목)

```
'announce' is deprecated. Use sendAnnouncement instead.
This API is incompatible with multiple windows.
```

새 시그니처는 `FlutterView`를 요구한다:
```dart
SemanticsService.sendAnnouncement(
  FlutterView view, String message, TextDirection textDirection,
  {Assertiveness assertiveness = Assertiveness.polite})
```
→ `BoardAnnouncer`가 `View.of(context)`를 보관하도록 수정했다.
→ 본 구현(3단계)에서도 `announce`가 아니라 `sendAnnouncement`를 쓴다.
→ 지원 여부는 `MediaQuery.supportsAnnounceOf(context)`로 조회 가능하며, UI에 노출해 뒀다.

### 2.3 빌드·정적 검사

| 항목 | 결과 |
|---|---|
| `flutter analyze` | ✅ **No issues found** |
| `flutter test` (좌표 파서 6케이스) | ✅ 전부 통과 |
| `flutter build windows --release` | ✅ 성공 (29.3초) |

좌표 파서 자동 검증 내용: I 건너뜀 · 아래가 1(19줄 좌상 화점 = **D16**) ·
`D16`/`d16`/`D 16`/`4-16` 동치 · `I5`·`D99`·`Z9`·잡문자 오류 구분 ·
`pass`/`패스`/`パス`/`停着` 명령 인식 · `?`·`?D16`·`?16` 질의 문법.

---

## 3. 스크린리더 실측 (미완 — 사람 수행 필요)

**자동화 불가.** 통과 기준이 "스크린리더가 실제로 말한 횟수"라 음성 뷰어 로그를 사람이 세야 한다.

### 실행 방법

```
spikes\board_a11y\build\windows\x64\runner\Release\board_a11y.exe
```

앱 우측 패널에 **앱이 내보낸 안내가 시각으로 기록**된다(시각·채널·문구).
스크린리더 음성 뷰어 로그와 나란히 놓고 대조하면 "내보냈는데 안 읽혔다"와
"애초에 안 내보냈다"를 구분할 수 있다.

### 환경
Windows 11 · **NVDA 2025.x 와 JAWS 2026 양쪽** · 기본 상세도·기본 속도 ·
음성 뷰어(NVDA) / 음성 히스토리(JAWS) 켜기 · 테스터 2인(1인은 작성자 아님)

### 통과 기준

| # | 기준 | 측정 | NVDA | JAWS |
|---|---|---|---|---|
| 1 | Tab이 판에 닿고 "19 줄 바둑판" + 조작 힌트 낭독 | 음성 로그에 문자열 존재 | ⬜ | ⬜ |
| 2 | 초당 2회 × 20번 → **정확히 20회** 좌표 낭독, 누락 0 | 음성 뷰어 줄 수 | ⬜ | ⬜ |
| 3 | 초당 8회 × 30번 → 마지막 입력 후 **500ms 내** 최종 좌표, 잔여 발화 ≤2 | 스톱워치 | ⬜ | ⬜ |
| 4 | 좌표 필드에 `D16`+Enter → **1000ms 내** 결과 낭독, 포커스 필드 유지 | 로그 + Tab 순서 | ⬜ | ⬜ |
| 5 | `I5` → I 건너뜀 안내, `Z99` → 범위 밖 안내 낭독 | 로그 | ⬜ | ⬜ |
| 6 | **포커스가 좌표 필드 안에 있을 때 반칙 오류가 낭독된다**<br>(이미 돌이 있는 자리를 다시 입력) | 로그 — **최대 위험 항목** | ⬜ | ⬜ |
| 7 | 착수 3초 뒤 상대 착수가 **1000ms 내** 낭독 (포커스가 좌표 필드에 있어도) | 로그 | ⬜ | ⬜ |
| 8 | 판이 포커스를 가두지 않음 (Tab·Esc 탈출, 브라우즈 모드 교착 없음) | 수동 | ⬜ | ⬜ |
| 9 | 커서 readout이 표시 배율 100%·200%에서 잘리지 않음 | 육안 | ⬜ | ⬜ |
| 10 | *(참고, 게이트 아님)* 확대경 400%가 포커스를 따라감 | 수동 | ⬜ | ⬜ |

### 실패 시 사다리 (실행 전에 확정된 것)

- **6 또는 7 실패** → 오류도 `value` 경로로 미러링하고 오류 시 판으로 포커스 왕복.
  그래도 실패면 좌표 필드가 유일한 포커스 소유자가 되고 모든 상태를 그 `value`에 싣는다.
- **2 또는 3 실패** → 화살표 커서를 **저시력 시각 보조 전용**으로 강등,
  좌표 명령어를 유일한 시각장애 조작 모델로. 여전히 출시 가능하지만 **날짜 있는 문서 결정**이어야 한다.
- **1·4·8 실패** → **중단.** Flutter는 이 제품의 스크린리더 경로를 Windows에서 담지 못한다.
  Flutter를 저시력·확대경 전용 데스크톱 클라이언트로 축소하고 스크린리더는 React 웹이 담당.

**이 표가 채워지기 전에는 2단계(엔진 포팅)를 시작하지 않는다.**

---

## 4. 구현 메모 (본 구현으로 넘길 것)

- 판 하위 **포커스 노드는 정확히 1개**. 361개 셀 위젯도, 셀 시맨틱스도 없다.
  판 전체를 `CustomPainter` 한 번의 `paint()`로 그린다.
- 커서 이동은 **`Semantics.value` 로만** 전달한다. `announce` 계열을 쓰지 않는다
  (웹의 300ms 삭제·공백 해킹을 구조적으로 회피).
- 커서 값은 **120ms 트레일링 디바운스 + 리딩 엣지** — 첫 입력 즉시, 연타는 최종 지점만.
- **좌표를 항상 문장 맨 앞에** 둔다. 발화가 끊겨도 위치는 전달된다.
- 모든 발화에 **화면상 쌍둥이**(`CursorReadout`, 32px 노란 글자)를 둔다.
- `Semantics(liveRegion: true)`는 쓰지 않는다 — 엔진에서 `polite` 하드코딩이라
  반칙 알림에 부적합. 본 구현에서는 CI 테스트로 금지를 강제할 것.
- 커서 십자선을 판 전체에 그린다 — 확대경 사용자의 위치 추적 보조.
