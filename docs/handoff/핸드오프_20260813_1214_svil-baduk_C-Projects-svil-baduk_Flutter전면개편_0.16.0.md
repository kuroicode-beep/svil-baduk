## 대상
- 프로젝트: svil-baduk
- 작업 폴더: `C:\Projects\svil-baduk`
- 세션 시각: 2026-08-13 12:14 (KST)

## 세션 요약

React+Vite+Tauri UI 를 **Flutter Windows 앱으로 전면 개편**했다(계획서 0~5단계 + 8단계 코드 절반). 커밋 30개, 208 파일, +22,223 / -408. React 앱은 웹 타깃으로 유지(0.9.x 동결).

## 완료된 작업

### 버전·저장소
- **0.9.1 → 0.16.0** (`VERSION`·`src/version.ts`·`package.json`·`README.md`·`app/pubspec.yaml`·`app/lib/version.dart`·`src-tauri/tauri.conf.json`·`src-tauri/Cargo.toml` 7개 파일 일치, `npm run version:check` exit 0)
- `main` HEAD = **`1b84283`**, origin/main 동일
- 작업 브랜치 `claude/ui-ux-game-experience-dd5b7a` 로컬·원격 모두 삭제
- 원격 브랜치는 `main` 하나만 남음

### 새 저장소 구조
| 경로 | 내용 |
|---|---|
| `src/` | React 웹 — 0.9.x 동결 |
| `app/` | **Flutter Windows 클라이언트 (주력)** |
| `spikes/board_a11y`, `spikes/webrtc_p2p` | 검증용, 폐기 예정 |
| `scripts/export_{changelog,i18n,curriculum}.mjs` | 데이터 변환 |
| `tools/engine_diff.mjs` | TS↔Dart 차분 테스트 fixture 생성 |

### 동작하는 기능
시작 화면 → 대국·배우기·설정 · 내장 AI 10단계 대국 · KataGo 연결(사망 시 내장 AI 강등) · 계가 추정 + 판에 집 표시 · 힌트·무르기·패스·기권 · SGF 내보내기/불러오기 · 배우기 9스테이지 28문제 + 진행 저장 · 좌표 명령어 5개 언어

### 검증 수치
- `flutter test` **319개 통과** / `npm test` **128개 통과**
- `flutter analyze --fatal-infos` **0 issues**
- Windows 릴리스 빌드 성공, 설치 용량 **28.6MB** (기준 60MB)
- i18n **272키 × 5언어 = 1,360 문자열**
- 규칙 엔진 차분: TS 판과 **500판 / 56,639수 / 54,787 판정 지점 완전 일치**

### 산출물 경로
- exe: `C:\Projects\svil-baduk\app\build\windows\x64\runner\Release\svil_baduk.exe`
- 바로가기: `C:\Users\kuroi\OneDrive\Desktop\SVIL Baduk.lnk`
- 바로가기 스크립트: `app/scripts/install_desktop_shortcut.ps1`
- 설치본 스크립트: `scripts/installer.iss`, `scripts/build-installer.ps1` (Inno Setup 필요, 미실행)
- 완료보고서: `docs/reports/완료보고서_20260813_Flutter전면개편_0.16.0_ClaudeCode.md`
- 체크리스트 4차 실행: `docs/reports/체크리스트_20260809_1차실행_ClaudeCode.md`
- Outline 위키: `/doc/svil-baduk-KxHTB3Zvdj` (0.16.0 절 추가)

## 진행 중 / 미완료 작업

### 장비·사람이 있어야 통과하는 것 (코드로 못 채움)
| 영역 | 필요한 것 | 항목 수 |
|---|---|---|
| 스크린리더 검증 | NVDA·JAWS, 테스터 2인 | 18 |
| P2P 전송 계층 | 서로 다른 네트워크의 Windows 2대 | 6 + 구현 |
| KataGo 실기 | KataGo 설치본 | 2 |
| 설치본 검증 | Inno Setup + 클린 VM | 6 |
| Android · iOS | 실기 · Mac + Apple Developer 계정 | 다수 |

### 코드 잔여
- `src-tauri/` 삭제 (React 웹이 아직 Tauri 셸 사용 — 7단계 종료 시)
- P2P 전송 계층: `flutter_webrtc` + 손으로 쓴 PeerJS 브로커 WebSocket 클라이언트. `peerdart` **사용 금지**(CI 가 강제)

### 정리 못 한 것
- 🔴 **워크트리 폴더 `C:\Projects\svil-baduk\.claude\worktrees\game-overall-improvement-20728a` (1,337MB) 가 디스크에 잔존.** git 등록·메타데이터·브랜치는 전부 정리됐고 `git worktree list` 에 `main` 만 남는다. 폴더만 남은 이유는 **그 세션의 셸 작업 디렉터리가 그 폴더 안이라 자기 자신을 지울 수 없어서**다. 그 세션을 닫은 뒤 지우면 된다:
  ```powershell
  Remove-Item "C:\Projects\svil-baduk\.claude\worktrees\game-overall-improvement-20728a" -Recurse -Force
  ```
- **`claude/game-overall-improvement-20728a` 브랜치**에 `main` 에 없는 커밋 1개(`97d7be7` "feat: overhaul AI heuristics, learn tracks, and game UX (0.9.0)")가 남아 있다. 이번 세션 작업이 아니라 **건드리지 않았다.** 병합할지 버릴지 판단 필요.

## 주요 결정사항 / 규칙

### 바둑판 접근성 — 격자를 흉내내지 않는다
Flutter 에는 `grid`/`gridcell` 역할이 없고 `aria-activedescendant` 도 없으며, Windows 는 MSAA 만 말한다(UIA 는 `FLUTTER_ENGINE_USE_UIA` 뒤로 컴파일 아웃, issue #94782 2021년부터 열림). **격자의 행·열 좌표를 스크린리더에 전달할 통로 자체가 없다.**

→ 판을 "탐색하는 공간"이 아니라 **값을 가진 컨트롤 하나 + 좌표 명령어 언어**로 만들었다.
- 판 안의 포커스 노드는 **정확히 1개** (361개 셀 위젯 없음)
- 커서 위치는 `Semantics.value` 로만 나간다 — `announce` 는 웹에서 300ms 뒤 문자열을 지워 빠른 커서 이동에 유실된다
- `Semantics(liveRegion:)` **금지** (엔진에서 `polite` 하드코딩) — `test/lint/guardrails_test.dart` 가 강제
- `SemanticsService.announce` 는 3.35 이후 deprecated → `sendAnnouncement`
- 좌표 텍스트 입력은 보조가 아니라 **동등한 1급 경로**

### 하우스 관례
- `app/domain/` 은 순수 Dart — `package:flutter` import 금지 (테스트가 강제)
- 상태관리 패키지 없음 — `ChangeNotifier` + 손으로 만든 `AppContainer`
- `windows/CMakeLists.txt` 의 `/utf-8` 삭제 금지 — 한국어 로케일(CP949)에서 UTF-8 소스를 가진 플러그인(`flutter_webrtc` 등)이 C4819 로 빌드 실패

### 버전 규칙
`src/history/changelog.ts` 가 changelog 정본. `app/lib/domain/changelog.dart` 는 `scripts/export_changelog.mjs` 가 재생성하므로 **거기에 손으로 쓰면 덮인다.**

## 참고 정보

### 조용히 통과하던 결함 (테스트가 초록인데 틀렸던 것)
1. 🔴 **`main.dart` 가 1단계 스캐폴드 그대로였다.** 3단계 대국 화면이 6단계까지 앱에 연결되지 않았다. 테스트 289개가 통과하는데 앱을 켜면 안내문만 나왔다. → `test/ui/app_boot_test.dart` 추가(홈에서 각 화면까지 실제로 이동).
2. **`GoRules` 가 `settings_store.dart` 와 `scoring.dart` 두 곳에 정의** — 서로 다른 타입이라 룰 설정이 `estimateScore` 에 도달 불가. 엔진 쪽을 정본으로 하고 store 가 re-export.
3. **테마 enum 4개에 한국어 라벨이 박혀 있었다** — 아무도 안 써서 테스트가 안 잡았다. i18n 으로 이전.
4. **좌표 명령 `score`·`hint`·`undo` 가 빈 문자열 반환** — 접근성 A13 의 조용한 실패.
5. **좌표 뒤집기가 두 번** — `pointLabel` 과 GTP 파서가 정확한 역함수여서 **왕복 테스트가 완벽히 통과하는 동안 KataGo 는 거울 판에서 뒀다.** → `test/domain/gtp_coord_test.dart` 가 왕복이 아니라 **알려진 값**(19줄 좌상 화점 = D16)으로 못박는다.

### 성능
내장 AI 가 O(n²)였다(수마다 상대 전 합법수 시뮬레이션). 1000판 테스트가 10분 타임아웃 초과. `capturePoints`(따냄 = 상대 그룹의 마지막 활로)로 교체해 O(판 크기)로. **첫 구현은 패·슈퍼코를 안 걸러 틀렸고, 전수 시뮬레이션과의 동치성 테스트가 잡았다**(`test/domain/capture_points_test.dart`).

### 영구 한계 (기계 검증 불가)
- `kill`/`live` 학습 목표는 **사활 판정기 없이 검증 불가**. 계획서가 지적한 "아무것도 죽지 않는 문제 3개가 CI 통과"의 원인. 사활 판정기는 범위 밖 → **영구히 사람 검토 대상**(테스트 주석에 명시).
- 계가는 **사석을 판정하지 못한다.** 오차를 실제 국면으로 고정한 테스트가 있고(76 vs 78), 설정 화면에 한계를 문장으로 적었다.

### 랜딩페이지 상태
- gh-pages 브랜치 **원격에 없음**, GitHub Release **없음**
- `README.md` 에 `npm run deploy` (gh-pages 배포) 스크립트는 있으나 실행 흔적 없음
- Outline 「SVIL 프로젝트 현황」의 "svil-baduk — GitHub Pages 라이브" 표기는 **사실과 다름**(확인 필요)
- 루트 `index.html` 은 Vite 진입점이지 랜딩페이지가 아님
- → 0.16.0 데스크톱 앱의 소개·다운로드 페이지가 **없다**. 사용자 판단 대기.

## 다음 세션 시작 시 할 일

1. 🔴 **스크린리더 실측** (5분) — `spikes\board_a11y\build\windows\x64\runner\Release\board_a11y.exe` 를 NVDA 로 켜고 **6번 항목**(포커스가 좌표 입력칸에 있을 때 반칙 오류가 낭독되는가)만 확인. 결과에 따라 `solo_screen.dart` 의 `RejectedMove` 경로가 `value` 미러링으로 바뀌어야 할 수 있다. **이게 판 접근성 설계의 분기점**이라 다른 접근성 작업보다 먼저다.
2. **워크트리 폴더 삭제** — 위 명령 한 줄.
3. **`claude/game-overall-improvement-20728a` 브랜치 처리 판단** — 커밋 1개 미병합.
4. **랜딩페이지 여부 결정** — 만들기로 하면 `svil-landing-page` 스킬.
5. **설치본 생성 검증** — Inno Setup 설치 후 `npm run app:installer`.
6. P2P 전송 계층 (Windows 2대 확보 시)
