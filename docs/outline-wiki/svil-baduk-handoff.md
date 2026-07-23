# SVIL Baduk 작업지시서

**작성일:** 2026-07-23  
**작성:** Cursor  
**대상:** 다음 세션 AI / 개발자  
**기준 버전:** 0.1.0 (`main`)

---

## 1. 프로젝트 위치

| 항목 | 경로·URL |
|------|----------|
| 로컬 | `C:\Projects\svil-baduk` |
| GitHub | https://github.com/kuroicode-beep/svil-baduk (public) |
| Vault | `G:\내 드라이브\SVIL Vault\03_PRJ\svil-baduk\` |
| 실행 | `npm install` → `npm run dev` |

## 2. 문서 맵

| 문서 | 경로 |
|------|------|
| PRD | `docs/prd/PRD_20260723_고대비바둑_Cursor.md` |
| 스펙 | `docs/prd/SPEC_20260723_기능스펙_Cursor.md` |
| 아키텍처 | `docs/architecture/ARCH_20260723_시스템아키텍처_Cursor.md` |
| 스토리보드 | `docs/storyboard/STORY_20260723_화면스토리보드_Cursor.md` |
| 로드맵 | `docs/prd/ROADMAP_20260723_로드맵_Cursor.md` |
| 본 지시서 | `docs/handoff/HANDOFF_20260723_작업지시서_Cursor.md` |

규칙: `CLAUDE.md`, `AGENTS.md`, `VERSIONING.md`

## 3. 완료된 작업

1. React+Vite MVP 스캐폴드 및 public 원격 푸시
2. 엔진: 착수·따냄·패·패스 종료 + vitest
3. UI: 고대비 보드, 깜빡임, 키보드 착수
4. 배우기 / 혼자 두기(급단·내장AI) / P2P 멀티
5. 설정(글꼴·크기·언어·히스토리), KataGo GTP 스텁

## 4. 미완료 · 다음 할 일 (우선순위)

### P0 — 품질
1. P2P: NAT 실패 메시지, 연결 끊김 후 로비 복귀
2. 엔진: 패(코) 단위 테스트 추가
3. 커밋 메시지에 섞인 `EOF` 정리(필요 시 새 chore 커밋, amend+force 금지)

### P1 — v0.2
1. 사활/따냄 연습 문제를 `learn`에 보드 연동
2. 방 ID QR
3. 초보 계가

### P2 — v0.3
1. Tauri 도입 + KataGo spawn
2. 설정에서 exe/model 경로 지정
3. visits 매핑 실측 튜닝

### 문서/인프라
1. Outline 프로젝트 위키 허브 생성(게이트웨이 복구 후)
2. (선택) gh-pages 배포

## 5. 기술 제약 (지키면 됨)

- **대국 서버 만들지 말 것** — P2P 유지
- UI는 SVIL 고대비 토큰, 색만으로 상태 구분 금지
- KataGo 바이너리/모델 git 커밋 금지 (`katago/**` gitignore)
- 설정에 히스토리 메뉴 유지, 버전 올리면 `src/history/changelog.ts` 갱신
- 문서 이중 저장: `docs/` + Vault `03_PRJ\svil-baduk\`

## 6. 검증 명령

```powershell
cd C:\Projects\svil-baduk
npm test
npm run build
npm run dev
```

수동:
- 9줄 혼자 두기: 따냄·연속 패스 종료
- 두 창 멀티: 방 ID로 연결 후 수 동기화
- 설정 변경 후 새로고침 유지
- 보드 Tab/Enter 착수

## 7. 결정 사항

| 결정 | 내용 |
|------|------|
| 스택 | React 19 + Vite + TS |
| 멀티 | PeerJS WebRTC, 서버리스 |
| AI | 내장 휴리스틱 + KataGo transport |
| 저장소 | public |
| 계가 | v0.1 비목표, 로드맵 v0.2+ |

## 8. 주의 버그/부채

- `Solo` AI `useEffect`는 StrictMode 이중 호출에 주의 (cancelled 플래그 있음)
- 멀티는 v0.1 non-authoritative (양쪽 `tryPlay`) — 치팅/역동기 가능
- 레슨 문구는 아직 한국어만
- Outline MCP가 불안정할 수 있음 → `outline-publisher` 스크립트 사용

## 9. 인수인계 체크

- [ ] 위 문서 Vault 복사 확인
- [ ] `main` 최신 pull
- [ ] P0 중 1개 이상 처리 후 changelog 한 줄 추가
- [ ] Outline 위키 링크를 허브에 정리
