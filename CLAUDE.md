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
