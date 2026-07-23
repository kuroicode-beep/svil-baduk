# SVIL Baduk

저시력자를 위한 **고대비 바둑**.

- 저장소: https://github.com/kuroicode-beep/svil-baduk
- 버전: 见 `VERSION`

## 실행

```bash
npm install
npm run dev
```

## 기능

- 단계별 배우기 + 따냄 연습
- 혼자서 두기 (급/단, 내장 AI / KataGo 브리지)
- 상대랑 두기 (WebRTC P2P + 방 ID QR)
- 고대비 보드 · 착수점 깜빡임 · 키보드 착수 · 착수음
- 초보 계가 · 집 영역 표시 · SGF 저장/복기

## KataGo

```powershell
npm run katago:setup    # 바이너리(OpenCL) + b20 모델 다운로드
npm run katago:bridge   # HTTP GTP 브리지 (기본 자동연결)
# 또는: npm run dev:all
```

앱 기본값: 시작 시 브리지에 자동 연결 (`설정`에서 해제 가능).

앱 설정에서 브리지 연결.

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
| `npm run shortcut` | 바탕화면 「SVIL Baduk」 바로가기 |

## CI

`main` 푸시/PR 시 GitHub Actions에서 `npm test` + `npm run build` 실행.
