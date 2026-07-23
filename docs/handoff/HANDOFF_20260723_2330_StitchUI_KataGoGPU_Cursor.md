# 핸드오프_20260723_2330_StitchUI_KataGoGPU

## 세션 요약
- SVIL Baduk Stitch 고대비 UI 적용·마무리, KataGo가 RTX 5060 Ti GPU를 쓰는지 확인하고 체감 지연(전체 재착수)을 고침. 버전 0.7.0.

## 완료된 작업
- Stitch `stitch_svil_baduk_accessibility_interface.zip` → CSS/홈/설정/Solo·멀티·캐릭터
- 「버튼 대비 확실하게」설정 + 미리보기
- 브리지/프리뷰 콘솔 숨김
- KataGo 증분 보드 sync (`src/ai/katago.ts`), `katago/gtp_play.cfg` 스레드 12·Device 0·maxTime
- 난이도 visits/maxTimeSec 재조정 (`src/ai/ranks.ts`)

## 진행 중 / 미완료 작업
- Outline MCP 장애로 원격 핸드오프/위키 append 불가 → 로컬 `docs/handoff`·`docs/reports`·`docs/outline-wiki`만 갱신
- Tauri에 KataGo sidecar 내장 미착수

## 주요 결정사항 / 규칙
- 대화 한국어 · Stitch/외부 프롬프트 영어 (유저 룰)
- KataGo는 브라우저 WebGL과 별개로 로컬 OpenCL/CUDA GPU 사용
- 시작프로그램 등록 안 함 (일반 데스크톱 앱)

## 참고 정보
- 로컬: `C:\Projects\svil-baduk`
- 디자인: `docs/DESIGN_20260723_Stitch비전_Cursor.md`
- 완료보고: `docs/reports/완료보고_20260723_StitchUI·KataGoGPU_Cursor.md`
- 브리지 로그 확인: `Using OpenCL Device 0: NVIDIA GeForce RTX 5060 Ti`

## 다음 세션 시작 시 할 일
1. Outline Gateway 재연결 후 위키/핸드오프 원격 반영
2. (선택) CUDA 12.8 + KataGo CUDA 빌드
3. 사용자 체감으로 AI 수 응답 재확인 후 visits 미세 조정
