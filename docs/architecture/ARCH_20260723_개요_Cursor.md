# 아키텍처 개요

```
UI (React)
  ├─ Learn / Solo / Multi / Settings
  ├─ Board (SVG, a11y focus)
  └─ i18n + settings store
Engine (순수 TS)
  └─ 착수 · 따냄 · 패 · 패스 종료
AI
  ├─ builtin heuristic (급단 randomness)
  └─ katago GTP transport (사이드카 연결점)
P2P
  └─ PeerJS → WebRTC DataChannel (수 동기화)
```

## KataGo 연동 (다음 마일스톤)

Tauri/Electron에서 `katago.exe gtp` spawn → stdin/stdout 라인 프로토콜 → `setKataGoTransport`.

## P2P

앱 전용 서버 없음. PeerJS 클라우드 시그널만 사용. 방 ID 공유로 연결.
