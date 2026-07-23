# 완료보고_20260723_StitchUI·KataGoGPU_Cursor

## 요약
SVIL Baduk 0.7.0 — Stitch 접근성 디자인 적용, 데스크톱 셸/코드사인 이후 UX 다듬기, KataGo RTX 5060 Ti 체감 속도 개선까지 마무리.

## 완료
- Tauri 2 셸·NSIS·Authenticode 훅 (이전 커밋 `779900e` 포함 세션 연속)
- 전체화면·한 화면 보드 레이아웃
- 서버/브리지 콘솔 숨김 (`scripts/background.ps1`, `start-tauri.ps1`)
- Stitch zip 비전 반영: 토큰·버튼(흰/검정)·홈 2열·설정 대비 미리보기·Solo/멀티/캐릭터 2열
- 설정: 「버튼 대비 확실하게」
- KataGo: OpenCL이 Device 0(RTX 5060 Ti) 사용 확인. 매 수 `clear_board` 제거(증분 sync), `numSearchThreads=12`, visits/maxTime 상한

## 검증
- `npm test` 26통과
- `npm run tauri:build` / 바로가기 갱신 (마무리 시점에 재실행)

## 미완료 / 다음
- Outline Gateway MCP 재연결 후 원격 위키·핸드오프 업로드
- CUDA Toolkit 설치 시 CUDA 빌드 KataGo로 추가 가속 가능
- KataGo sidecar를 Tauri에 내장(브리지 불필요)은 이후

## 산출물
- exe: `src-tauri/target/release/svil-baduk.exe`
- 설치본: `src-tauri/target/release/bundle/nsis/SVIL Baduk_0.7.0_x64-setup.exe` (빌드 성공 시)
- 바로가기: 바탕화면 `SVIL Baduk.lnk`
- 디자인: `docs/DESIGN_20260723_Stitch비전_Cursor.md`
