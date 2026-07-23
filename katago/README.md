# KataGo 로컬 배치

## 빠른 설치

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-katago.ps1
npm run katago:bridge
```

또는 Vite와 함께: `npm run dev:all`

앱 기본값은 **시작 시 KataGo 브리지 자동 연결**입니다 (`katagoAutoConnect: true`).

## 수동 배치

1. [KataGo Releases](https://github.com/lightvector/KataGo/releases) — Windows OpenCL `katago.exe` → `bin/`
2. 네트워크 가중치(`.bin.gz`) → `models/` (권장: g170e b20)
3. (선택) `gtp_play.cfg` — 대국용 (기본 visits 낮춤). 없으면 `default_gtp.cfg`

## 경로

| 항목 | 기본 |
|------|------|
| exe | `katago/bin/katago.exe` |
| model | `katago/models/*.bin.gz` (첫 파일) |
| config | `katago/gtp_play.cfg` → `default_gtp.cfg` |
| bridge | `http://127.0.0.1:17419` |

바이너리·모델은 gitignore됩니다.
