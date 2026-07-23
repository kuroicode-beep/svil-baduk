# SVIL Baduk

저시력자를 위한 **고대비 바둑**.

- 저장소: https://github.com/kuroicode-beep/svil-baduk
- 버전: `VERSION` 파일 / 앱 홈 배지 (현재 0.6.7)
- Pages: `npm run deploy` 후 `/svil-baduk/`
- 데스크톱: Tauri 2 (`npm run tauri:dev` / `tauri:build`)

## 실행

```bash
npm install
npm run dev
```

### 데스크톱 (Tauri)

```bash
npm run tauri:dev      # 개발
npm run tauri:build    # NSIS 설치본 + exe
npm run codesign:setup # 로컬 자체서명 인증서 (개발용)
npm run shortcut:tauri # 빌드된 exe로 바탕화면 바로가기
```

코드사인: `SVIL_CODESIGN_THUMBPRINT`가 있거나 `Cert:\CurrentUser\My`에
`SVIL Baduk` 인증서가 있으면 빌드 시 `scripts/sign-windows.ps1`이 서명합니다.
없을 때는 서명만 건너뜁니다. 강제하려면 `SVIL_CODESIGN_REQUIRED=1`.

## 기능

- **AI와 겨루기** — 난이도 1~10, 내장 AI / KataGo 브리지
- 캐릭터 생성 · 레벨업 · 전적 · 최고 점수
- 단계별 배우기 + 따냄 연습
- 상대랑 두기 (WebRTC P2P + 방 ID QR)
- 일본식/중국식 룰·덤, SGF 저장/복기, AI 힌트(상위 3수 라벨)
- 고대비 보드 · 착수점 깜빡임 · 키보드 착수 · 힌트 `H` · 포커스 `#FFFF00`

## KataGo

```powershell
npm run katago:setup    # 바이너리(OpenCL) + b20 모델 다운로드
npm run katago:bridge   # HTTP GTP 브리지 (기본 자동연결)
# 또는: npm run dev:all
```

앱 기본값: 시작 시 브리지에 자동 연결 (`설정`에서 해제 가능).

## 스크립트

| 명령 | 설명 |
|------|------|
| `npm run dev` | 개발 서버 |
| `npm test` | 단위 테스트 |
| `npm run build` | 프로덕션 빌드 |
| `npm run build:gh` | GitHub Pages용 빌드 (`/svil-baduk/`) |
| `npm run deploy` | `gh-pages` 브랜치 배포 |
| `npm run katago:bridge` | 로컬 KataGo GTP HTTP 브리지 |
| `npm run start:app` | 빌드 후 preview + 브리지 실행 |
| `npm run shortcut` | 바탕화면 「SVIL Baduk」 바로가기 (preview) |
| `npm run tauri:dev` | Tauri 개발 셸 |
| `npm run tauri:build` | Tauri 릴리스(NSIS) |
| `npm run codesign:setup` | 로컬 코드사인 인증서 생성 |
| `npm run shortcut:tauri` | Tauri exe 바탕화면 바로가기 |

## CI

`main` 푸시/PR 시 GitHub Actions에서 `npm test` + `npm run build` 실행.

## 문서

로컬 Outline 미러: `docs/outline-wiki/` (허브 `svil-baduk-project-wiki.md`).
