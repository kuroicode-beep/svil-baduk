# SVIL Baduk 기능 스펙

**버전:** 0.1.0  
**작성일:** 2026-07-23  
**대응 PRD:** `PRD_20260723_고대비바둑_Cursor.md`

---

## 1. 범위

본 스펙은 v0.1 MVP와 v0.2~0.3 예정을 구분한다.  
구현 위치는 저장소 경로로 적는다.

## 2. 공통

### 2.1 화면 라우팅
| 화면 ID | 설명 | 구현 |
|---------|------|------|
| `home` | 메인 메뉴 | `src/screens/Home.tsx` |
| `learn` | 단계별 배우기 | `src/screens/Learn.tsx` |
| `solo` | 혼자서 두기 | `src/screens/Solo.tsx` |
| `multi` | 상대랑 두기 | `src/screens/Multi.tsx` |
| `settings` | 설정·히스토리 | `src/screens/Settings.tsx` |

네비게이션: 상태 `screen` (React). Alt+← → `home`.

### 2.2 설정
| 항목 | 값 | 저장 |
|------|-----|------|
| 언어 | ko/en/ja/zh/vi | `localStorage` `svil-baduk-settings` |
| 글꼴 | 8종 (교보손글씨2019 기본) | 동일 |
| 글자 크기 | small 16 / medium 18 / large 20 | 동일 |
| 착수점 깜빡임 | on/off | 동일 |
| 최대 대비 보드 | on/off | 동일 |
| 움직임 줄이기 | on/off | 동일 |

### 2.3 i18n
- 사전: `src/i18n/dict.ts`
- UI 문자열 하드코딩 금지(레슨 본문은 v0.1 한국어 고정, 이후 i18n)

## 3. 규칙 엔진

**파일:** `src/engine/board.ts`, `types.ts`

| 규칙 | 동작 |
|------|------|
| 착수 | 빈 교차점, 차례 교대 |
| 따냄 | 상대 그룹 활로 0이면 제거, 포획 수 증가 |
| 자살 | 착수 후 자기 그룹 활로 0이면 거부 (따냄으로 해소 시 허용) |
| 패 | 단일 따냄 직후 즉시 되따냄 좌표 금지 |
| 패스 | 연속 2회 패스 시 `ended=true` |
| 판 크기 | 9 / 13 / 19 |

API:
- `createGame(size)`
- `tryPlay(state, x, y)` → `{ok, state, move} | {ok:false, reason}`
- `pass(state)`
- `legalMoves(state)`

**미구현:** 집 계산, 덤, 사석 확정, 형세 판단.

## 4. 보드 UI

**파일:** `src/components/Board.tsx`

| 항목 | 스펙 |
|------|------|
| 렌더 | SVG, cell 48px, 돌 라벨(흑/백) |
| 합법 착수점 | 노란 점, 깜빡임 애니메이션 |
| 포커스 | 키보드 포커스 점 강조, Enter/Space 착수 |
| 직전 수 | 돌 위 노란 작은 원 |
| 히트 영역 | 빈 점 투명 원 클릭 |
| a11y | `role="application"`, 포커스 링 `#ffd479` |

## 5. 모드별 스펙

### 5.1 배우기
- 데이터: `src/learn/lessons.ts` (4 레슨)
- 진행: 레슨 인덱스 + 스텝 인덱스
- 완료 문구 후 혼자 두기 유도

### 5.2 혼자 두기
| 설정 | 값 |
|------|-----|
| 급단 | `src/ai/ranks.ts` 30k~5d |
| AI | `pickBuiltinMove` / `katagoGenmove` |
| 턴 | `myColor`일 때만 입력, AI 턴 시 상태 문구 |

### 5.3 멀티
| 메시지 | 필드 |
|--------|------|
| `hello` | name, size, hostColor |
| `accept` | name |
| `move` | Move |
| `resign` | player |
| `sync-request` | (게스트→호스트) |

연결: `src/p2p/session.ts` PeerJS.

### 5.4 KataGo
- `src/ai/katago.ts`: transport 주입, GTP `boardsize`/`clear_board`/`play`/`genmove`
- 바이너리 경로: `katago/bin/`, 모델: `katago/models/` (gitignore)
- visits ↔ 급단 매핑은 ranks 테이블 (사이드카에서 적용 예정)

## 6. 수락 기준 (v0.1)

1. `npm test` 엔진 테스트 통과
2. `npm run build` 성공
3. 9줄 혼자 두기에서 따냄·패스 종료 가능
4. 설정 변경이 새로고침 후에도 유지
5. 보드 포커스 후 키보드만으로 착수 가능

## 7. 이후 스펙 후보

- 계가(일본/중국 룰 선택)
- 사활 문제 세트
- Tauri + KataGo spawn
- P2P QR·TURN
- 기보 SGF 저장/불러오기
