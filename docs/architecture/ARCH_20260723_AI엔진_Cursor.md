# SVIL Baduk AI 엔진

## 구성

| 엔진 | 경로 | 언제 |
|------|------|------|
| 내장 휴리스틱 | `src/ai/builtin.ts` | KataGo 미연결 시 기본 |
| KataGo | 로컬 `katago.exe` + GTP 브리지 | 설정에서 브리지 연결 시 |

## 내장 AI

- 합법수만 후보
- 따냄·중앙 선호 점수 + 급단 `randomness`
- 강하지 않음 — 입문·오프라인용

## KataGo

1. 바이너리 → `katago/bin/katago.exe`
2. 모델 → `katago/models/*.bin.gz`
3. `npm run katago:bridge` (또는 `npm run dev:all`)
4. 앱 설정 → KataGo 브리지 연결

급단 → `maxVisits` 힌트 (`src/ai/ranks.ts`).

Transport: `src/ai/bridgeTransport.ts` → `http://127.0.0.1:17419/gtp`
