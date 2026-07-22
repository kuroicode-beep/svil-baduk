# SVIL Baduk

저시력자를 위한 **고대비 바둑**.

## 실행

```bash
npm install
npm run dev
```

## 기능 (v0.1)

- 단계별 배우기
- 혼자서 두기 (급/단, 내장 AI)
- 상대랑 두기 (WebRTC P2P)
- 착수점 깜빡임 · 키보드 착수 · 최대 대비 보드
- KataGo GTP 연결 포인트 (`src/ai/katago.ts`)

## 스크립트

| 명령 | 설명 |
|------|------|
| `npm run dev` | 개발 서버 |
| `npm test` | 엔진 단위 테스트 |
| `npm run build` | 프로덕션 빌드 |
