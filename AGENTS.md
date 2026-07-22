# Agent notes — svil-baduk

저시력 고대비 바둑. 자세한 규칙은 `CLAUDE.md`, 버전은 `VERSION` / `VERSIONING.md`.

- UI는 SVIL 고대비 다크 + 교보손글씨2019 폴백, 터치 50px+, 포커스 `#ffd479`
- 색만으로 상태 구분 금지 (흑/백 라벨, 깜빡임+포커스 링 병행)
- KataGo는 로컬 GTP — 브라우저에서는 내장 AI 폴백
- 멀티는 서버리스 P2P(PeerJS). 대국 서버를 두지 말 것
- 설정에 글꼴·글자크기·언어·히스토리 유지
