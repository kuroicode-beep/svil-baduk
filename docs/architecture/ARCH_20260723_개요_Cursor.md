# 아키텍처 개요 (요약)

상세본: [`ARCH_20260723_시스템아키텍처_Cursor.md`](./ARCH_20260723_시스템아키텍처_Cursor.md)

```
UI (React)
  ├─ Learn / Solo / Multi / Settings
  ├─ Board (SVG, a11y focus)
  └─ i18n + settings store
Engine (순수 TS) — 착수 · 따냄 · 패 · 패스 종료
AI — builtin heuristic + KataGo GTP transport
P2P — PeerJS → WebRTC DataChannel
```

- KataGo: 데스크톱 사이드카 spawn 예정
- P2P: 앱 전용 대국 서버 없음
