# SVIL Baduk

저시력·스크린리더 사용자를 위한 **고대비 바둑** — 판을 보지 않고도 한 판을 끝낼 수 있게 만들었다.

- 랜딩: https://kuroicode-beep.github.io/svil-baduk/
- 다운로드: https://github.com/kuroicode-beep/svil-baduk/releases (Windows 설치본)
- 버전: `VERSION` 파일 / 앱 제목줄 (현재 0.20.0)

## 설치 (Windows)

[Releases](https://github.com/kuroicode-beep/svil-baduk/releases)에서 `SVIL-Baduk-<버전>-setup.exe`를 받아 실행한다.
자체 서명이라 SmartScreen 경고가 뜨면 **추가 정보 → 실행**. 별도 런타임 설치는 필요 없다.
제거해도 설정·전적·학습 진행은 남는다 (`%APPDATA%` 아래 shared_preferences).

## 접근성 — 무엇이 다른가

- **판 안의 포커스 노드는 정확히 1개.** 커서 위치·돌·화점이 `Semantics.value`로 낭독된다.
  361개 셀을 탐색하는 대신 화살표로 움직이고 값을 듣는다.
- **좌표 텍스트 입력이 1급 경로다.** `D16` 하나로 착수까지 끝난다 — 보조 수단이 아니다.
- 모든 발화에 **화면상 쌍둥이**(readout)가 있다. 낭독이 유실돼도 정보는 화면에 남는다.
- 반칙은 침묵하지 않고 **구체적 사유**(자리 있음·패·슈퍼코·자살수)를 말한다.
- 인앱 대비 프로파일 3종 + 바둑판 팔레트 + 포커스 링 색 선택 — Windows OS 고대비는
  Flutter 표면에 영향이 없어(실측) 앱이 직접 제공한다.
- 기권은 항상 확인창을 거친다. 색만으로 상태를 구분하지 않는다.

## 좌표 명령어 (좌표칸에 입력)

| 입력 | 동작 |
|---|---|
| `D16` `d16` `D 16` `4-16` | 착수 (아래가 1, I열 건너뜀) |
| `패스` / `pass` | 패스 |
| `기권` / `resign` | 기권 (확인창 경유) |
| `무르기` / `undo` | 무르기 (AI 대국은 2수 — P2P에서는 불가) |
| `계가` / `score` | 계가 추정 낭독 |
| `힌트` / `hint` | 추천 수 3개 + 커서 이동 (P2P에서는 불가) |
| `?` | 판 요약 |
| `?D16` / `?16` | 그 점 / 그 줄 읽기 |
| `r` | 마지막 발화 반복 |
| `help` | 도움말 |

명령어는 **5개 언어**(한국어·영어·일본어·중국어·베트남어) 전부 받는다 (`パス`·`停着`·`bỏlượt`…).

## 기능

- **AI와 겨루기** — 난이도 1~10 내장 AI, KataGo(GTP 직결) 선택 시 자동 탐색·강등
- **단계별 배우기** — 9스테이지 28문제, 전부 키보드만으로 풀 수 있다
- **상대랑 두기** — WebRTC P2P (방 ID 한 글자씩 낭독·QR·복사, 자동 재접속)
- 캐릭터(별명·급수·레벨·경험치·전적) · 일본/중국룰 · SGF 내보내기/가져오기
- 서체: LINE Seed KR 번들 (SVIL 표준)

## 저장소 구조

```
app/     Flutter Windows 클라이언트 (주 개발 대상)
src/     React 웹 (0.9.x 동결 — 보안·의존성 업데이트만)
scripts/ 버전 동기화 · i18n/커리큘럼 변환 · 설치본 빌드
docs/    prd · architecture · storyboard · handoff · reports
```

## 개발

```bash
# Flutter (데스크톱)
cd app && flutter analyze --fatal-infos && flutter test
npm run app:installer     # 릴리스 빌드 → Inno Setup → 서명

# React (웹)
npm install && npm run dev
npm test && npm run build
npm run deploy            # gh-pages 배포

# 공통
npm run version:check     # 버전 파일 5곳 일치 확인
npm run engine:diff       # TS↔Dart 엔진 차분 fixture
```

실측 검증(수동 실행):

```bash
cd app && flutter test test_live/broker_live_test.dart            # 실서버 시그널링
cd app && flutter test integration_test/p2p_e2e_test.dart -d windows  # 실기 WebRTC E2E
```

## CI

`main` 푸시/PR 시 GitHub Actions에서 React(`npm test`+build)와 Flutter(analyze+test) 실행.

## 문서

- 접근성 모델과 그 이유: `CLAUDE.md` · `docs/architecture/`
- 완료보고서: `docs/reports/`
- 로컬 Outline 미러: `docs/outline-wiki/`
