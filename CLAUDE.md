# SVIL Baduk

저시력자를 위한 고대비 바둑 클라이언트.

## 스택

- React 19 + Vite + TypeScript
- 규칙 엔진: `src/engine/`
- 내장 AI + KataGo GTP 스텁: `src/ai/`
- P2P: PeerJS WebRTC (`src/p2p/`)
- UI: SVIL 고대비 다크 토큰

## 버전

현재: `VERSION` 파일. 규칙: `VERSIONING.md`.

## 히스토리 메뉴

설정 → 히스토리에 `src/history/changelog.ts` 내용을 표시. 버전 올릴 때 여기도 갱신.

## 문서 이중 저장

완료보고서·요청문서:

1. 로컬 `docs/reports/` (또는 성격별 하위)
2. Vault `G:\내 드라이브\SVIL Vault\03_PRJ\svil-baduk\`

파일명: `카테고리_YYYYMMDD_내용_작업자.md`

## docs/

`prd/` `architecture/` `storyboard/` `handoff/` `reports/`

## 개발

```bash
npm install
npm run dev
npm test
npm run build
```

## Flutter 전환 (진행 중)

PC(Windows) 버전을 Flutter 로 개편 중이다. React 앱은 **웹 타깃으로 유지**한다.

### 저장소 구조
- `src/` — React 웹 (0.9.x 로 동결, 보안·의존성 업데이트만)
- `app/` — Flutter Windows 클라이언트 (`svil-task-monitor` 구조를 따름)
  - `domain/` 은 순수 Dart — `package:flutter` 를 import 하지 않는다 (테스트가 강제)
  - 상태관리 패키지를 쓰지 않는다. `ChangeNotifier` + `AppContainer` (하우스 관례)
- `spikes/` — 1단계 검증용, 폐기 예정
- `scripts/export_*.mjs` — 데이터는 손으로 옮기지 않고 스크립트로 변환한다

### 바둑판 접근성 — 왜 이런 구조인가
Flutter 에는 `grid`/`gridcell` 역할이 없고, `aria-activedescendant` 도 없으며,
Windows 는 MSAA 만 말해서 격자의 행·열 좌표를 스크린리더에 전달할 **통로 자체가 없다**.
그래서 판을 "탐색하는 공간"이 아니라 **값을 가진 컨트롤 하나 + 좌표 명령어 언어**로 만들었다.

- 판 안의 포커스 노드는 **정확히 1개**. 361개 셀 위젯도, 셀 시맨틱스도 없다.
- 커서 위치는 `Semantics.value` 로만 나간다. `announce` 는 웹에서 300ms 뒤 문자열을
  지우고 중복 발화를 막으려 공백을 번갈아 붙여서, 빠른 커서 이동에 유실된다.
- `Semantics(liveRegion:)` **금지** — 엔진에서 `polite` 하드코딩이라 반칙 알림에 못 쓴다.
  CI 테스트(`test/lint/guardrails_test.dart`)가 강제한다.
- `SemanticsService.announce` 는 3.35 이후 deprecated — `sendAnnouncement` 를 쓴다.
- 좌표 텍스트 입력은 보조가 아니라 **동등한 1급 경로**다.
- 모든 발화에 화면상 쌍둥이(`CursorReadout`)가 있다.
- Windows 는 `MediaQuery.highContrast` 를 영구히 false 로 보고한다(실측). OS 고대비는
  Flutter 표면에 영향이 없으므로 **인앱 대비 프로파일이 유일한 수단**이다.

### 빌드
```bash
cd app && flutter analyze --fatal-infos && flutter test
npm run app:installer     # 릴리스 빌드 → Inno Setup → 서명
npm run engine:diff       # TS 엔진과의 차분 테스트 fixture 생성
```

`windows/CMakeLists.txt` 의 `/utf-8` 을 지우지 말 것 — 한국어 로케일(코드페이지 949)에서
UTF-8 소스를 가진 플러그인(flutter_webrtc 등)이 C4819 로 빌드에 실패한다.
