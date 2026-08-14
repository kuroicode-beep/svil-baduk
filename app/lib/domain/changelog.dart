// lib/domain/changelog.dart — 인앱 히스토리 (설정 → 히스토리)
//
// 자동 생성 파일. 손으로 고치지 말 것.
// 원본: src/history/changelog.ts · 생성: npm run changelog:export

class HistoryEntry {
  const HistoryEntry({required this.version, required this.date, required this.lines});
  final String version;
  final String date;
  final List<String> lines;
}

const List<HistoryEntry> changelog = <HistoryEntry>[
  HistoryEntry(
    version: "0.17.0",
    date: "2026-08-14",
    lines: <String>[
      "홈 개편 — 프로필 카드(별명·급수·레벨·경험치·전적) + 메뉴 5개 + 도움말 (Stitch 기획 복원)",
      "캐릭터 화면 — 별명 편집. 급수는 이긴 최고 AI 난이도에서 유도",
      "대국 설정 화면 — 판 크기·상대·난이도를 고르고 시작",
      "AI 대국 전적·경험치 기록 (React 판 규칙 그대로, 백업 호환)",
      "상대랑 두기 메뉴를 준비 중으로 노출",
      "SVIL 표준 버튼 전역 적용 — 어두운 표면 + 테두리 + 둥근 모서리",
      "바탕화면 바로가기에 남아 있던 Tauri 시절 인자 제거 (백그라운드 기동 원인)",
    ],
  ),
  HistoryEntry(
    version: "0.16.1",
    date: "2026-08-14",
    lines: <String>[
      "판 첫 포커스에서 조작 안내를 1회 낭독 (NVDA 실측: hint 는 낭독되지 않음)",
      "홈·배우기 타일이 키보드 포커스에서 침묵하던 것 수정",
      "내 착수 낭독이 AI 즉답에 삼켜지던 것 수정 — 응수 반영에 최소 간격 700ms",
      "좌표 입력 오류 후 텍스트가 지워지던 것 수정 — 전체 선택으로 유지",
    ],
  ),
  HistoryEntry(
    version: "0.16.0",
    date: "2026-08-09",
    lines: <String>[
      "Flutter 데스크톱 앱 — 시작 화면에서 대국·배우기·설정으로 이동",
      "설정 화면: 대비·글자 크기·판 색·상대·난이도·룰 (전부 라디오 목록)",
      "배우기: 9단계 28문제, 진행 저장, 오답 사유 4종 구별",
      "내장 AI 대국 10단계 · KataGo 연결 · 엔진이 죽으면 내장 AI 로 이어 둠",
      "계가 추정: 집을 판에 사각형으로 표시 (돌은 원 — 색만으로 구분하지 않음)",
      "힌트 · 무르기 · SGF 내보내기 · 불러오기",
      "내장 AI 속도 개선 (한 수당 시뮬레이션 O(n²) → O(n))",
      "규칙 엔진을 순수 Dart 로 이식 — TS 판과 500판 차분 일치 확인",
    ],
  ),
  HistoryEntry(
    version: "0.9.1",
    date: "2026-08-09",
    lines: <String>[
      "바둑판에 좌표 눈금 표시 (네 면, 아래가 1선)",
      "바둑판 크기 설정이 실제로 판을 키웁니다 — 패널 폭을 줄여 자리를 냅니다",
      "바둑판을 그리기·입력·접근성 세 층으로 분리, 격자 접근성 개선",
      "착수 방식 선택: 바로 두기 / 고른 뒤 확정 (오터치 방지)",
      "설정 → 데이터: 설정·캐릭터·배우기 진행 내보내기·가져오기",
    ],
  ),
  HistoryEntry(
    version: "0.9.0",
    date: "2026-08-09",
    lines: <String>[
      "글자 크기 설정이 이제 화면 전체에 적용됩니다 (버튼·제목·좌표까지)",
      "모든 화면에 상단 바 — 홈·설정·버전이 항상 보입니다",
      "브라우저 뒤로가기 지원, 화면 주소 공유 가능 (#/설정 등)",
      "기권에 확인창 추가, 복기 중에는 기권이 잠깁니다",
      "동작 줄이기: 「시스템 설정 따름」이 기본 — OS에서 켜면 바로 반영",
      "설정 초기화 버튼 추가, 설정 저장 형식에 버전 관리 도입",
      "디자인 토큰 정리 — 색·간격·글자 크기를 한 곳에서 관리",
    ],
  ),
  HistoryEntry(
    version: "0.8.1",
    date: "2026-08-09",
    lines: <String>[
      "좌표 표기 수정: 19줄 좌상귀 화점을 D4가 아니라 D16으로 읽습니다 (아래에서 1선)",
      "판 위치 해시 압축·캐시로 착수 가능 지점 계산 약 2.6배 빠르게",
      "배우기 문제 배치에서 패·슈퍼코 판정이 어긋나던 문제 수정",
      "컴포넌트 테스트 환경(jsdom) 추가 — 화면·접근성 검증 가능",
    ],
  ),
  HistoryEntry(
    version: "0.8.0",
    date: "2026-07-24",
    lines: <String>[
      "배우기: 기본·포석·사활 3트랙 스테이지 클리어 코스",
      "유명 입문 교재 순서를 참고한 오리지널 문제(따냄·연결·치중·두 눈 등)",
      "스테이지 해금·클리어 진행 localStorage 저장",
    ],
  ),
  HistoryEntry(
    version: "0.7.6",
    date: "2026-07-24",
    lines: <String>[
      "직전 수·힌트 동심원 반경 약 절반으로 축소",
      "난이도 1~4: KataGo 대신 약한 내장 AI (완전/고랜덤)",
      "난이도 5+: KataGo visits·선택 온도 재조정",
    ],
  ),
  HistoryEntry(
    version: "0.7.5",
    date: "2026-07-24",
    lines: <String>[
      "직전 수·힌트 애니메이션: CSS 대신 JS(r/opacity)로 실제 깜빡임·동심원 동작",
      "보드 overflow 클리핑 제거 (링이 잘리던 문제)",
    ],
  ),
  HistoryEntry(
    version: "0.7.4",
    date: "2026-07-24",
    lines: <String>[
      "직전 수·AI 힌트: 두꺼운 동심원(검정+강조색) 퍼짐 강화",
    ],
  ),
  HistoryEntry(
    version: "0.7.3",
    date: "2026-07-24",
    lines: <String>[
      "미종료 대국: 앱/대국 재진입 시 바로 스냅샷 복원",
      "직전 수·AI 힌트: 돌 전체 깜빡임 + 동심원 퍼짐",
    ],
  ),
  HistoryEntry(
    version: "0.7.2",
    date: "2026-07-24",
    lines: <String>[
      "흑/백 돌 색 선택 (설정) · 상대 직전 수 내 착수까지 깜빡임",
      "우측 패널: 직전 좌표 확대 · 진행 중 집/합계 표시",
      "AI 대국 스냅샷 — 종료 후에도 이어서 두기",
    ],
  ),
  HistoryEntry(
    version: "0.7.1",
    date: "2026-07-24",
    lines: <String>[
      "AI 첫 수가 영구 대기하던 버그 수정 (aiBusy effect 자기취소)",
      "KataGo genmove 실패 시 내장 AI로 즉시 폴백",
    ],
  ),
  HistoryEntry(
    version: "0.7.0",
    date: "2026-07-23",
    lines: <String>[
      "Stitch 고대비 비전 UI (홈 2열·버튼·설정 미리보기·Solo/멀티/캐릭터)",
      "KataGo GPU(RTX 5060 Ti): 증분 보드 동기화·스레드/시간 상한",
      "서버 콘솔 숨김 실행 · 버튼 대비 확실하게 옵션 · 화점 고대비 표시",
    ],
  ),
  HistoryEntry(
    version: "0.6.9",
    date: "2026-07-23",
    lines: <String>[
      "설정: 버튼 대비 확실하게 옵션 (글자·테두리 강화)",
      "서버/브리지 콘솔 백그라운드(숨김) 실행",
      "Stitch 접근성 비전 디자인 적용 (홈 2열·버튼 시스템·설정 미리보기)",
      "KataGo: 보드 증분 동기화 + RTX 5060 Ti용 스레드/시간 상한 (체감 속도)",
    ],
  ),
  HistoryEntry(
    version: "0.6.8",
    date: "2026-07-23",
    lines: <String>[
      "대국 시작 시 전체화면",
      "바둑판·메뉴 한 화면 맞춤 정렬 (보드 잘림/스크롤 제거)",
    ],
  ),
  HistoryEntry(
    version: "0.6.7",
    date: "2026-07-23",
    lines: <String>[
      "Tauri 2 데스크톱 셸 (npm run tauri:dev / tauri:build)",
      "Windows Authenticode 코드사인 훅 (인증서 있을 때 자동 서명)",
      "바탕화면 바로가기: shortcut:tauri",
    ],
  ),
  HistoryEntry(
    version: "0.6.6",
    date: "2026-07-23",
    lines: <String>[
      "package.json homepage (GitHub Pages URL)",
      "로드맵: 배포 파이프라인 상태 갱신",
    ],
  ),
  HistoryEntry(
    version: "0.6.5",
    date: "2026-07-23",
    lines: <String>[
      "AI 대국: 난이도·판 크기·색깔 선택 기억",
    ],
  ),
  HistoryEntry(
    version: "0.6.4",
    date: "2026-07-23",
    lines: <String>[
      "README·Outline 로컬 위키를 0.6.x 기능에 맞춤",
      "배포/Pages·캐릭터·AI 대국 안내 정리",
    ],
  ),
  HistoryEntry(
    version: "0.6.3",
    date: "2026-07-23",
    lines: <String>[
      "포커스 링 #FFFF00 (고대비 표준)",
      "AI 힌트 단축키 H + 스크린리더 후보 낭독",
    ],
  ),
  HistoryEntry(
    version: "0.6.2",
    date: "2026-07-23",
    lines: <String>[
      "AI 힌트: 상위 3수 숫자·상대점수 라벨 (분석 색칠 1차)",
      "KataGo 연결 시 1순위 AI 수 + 보조 후보 표시",
    ],
  ),
  HistoryEntry(
    version: "0.6.1",
    date: "2026-07-23",
    lines: <String>[
      "설정: 일본식/중국식 룰 + 덤 계가 분기",
      "바로가기 런처 안정화 (포트 재사용·ASCII BOM)",
    ],
  ),
  HistoryEntry(
    version: "0.6.0",
    date: "2026-07-23",
    lines: <String>[
      "유저 캐릭터 생성(이름·상징)",
      "레벨업·XP, 전적(W/L/D), 최고 점수·최고 격파 난이도",
      "AI 대국 종료 시 프로필 반영",
    ],
  ),
  HistoryEntry(
    version: "0.5.3",
    date: "2026-07-23",
    lines: <String>[
      "설정: GPU/CPU 추정 안내 (WebGPU·WebGL)",
      "엔진 테스트: 자살수·따냄 케이스 추가",
    ],
  ),
  HistoryEntry(
    version: "0.5.2",
    date: "2026-07-23",
    lines: <String>[
      "AI 난이도 10단계(1 입문 ~ 10 고수)로 통일",
      "바탕화면 바로가기 스크립트 (start-app / install_desktop_shortcut)",
    ],
  ),
  HistoryEntry(
    version: "0.5.1",
    date: "2026-07-23",
    lines: <String>[
      "KataGo 로컬 설치 스크립트 (npm run katago:setup)",
      "브리지 기본 설정 gtp_play.cfg · 시작 시 자동연결 재시도",
      "OpenCL 바이너리 + g170e b20 모델 배치 안내",
    ],
  ),
  HistoryEntry(
    version: "0.5.0",
    date: "2026-07-23",
    lines: <String>[
      "핵심 모드 명확화: AI와 겨루기 (난이도·급단 선택)",
      "홈 첫 CTA로 AI 대국 배치 + 안내 문구",
      "설정: 입문/초급/중급/고급 난이도 밴드 + 급단",
    ],
  ),
  HistoryEntry(
    version: "0.4.9",
    date: "2026-07-23",
    lines: <String>[
      "혼자 두기: 엔진 표시 (내장 휴리스틱 / KataGo visits)",
      "급단 목록에 visits 병기 (KataGo 연결 시)",
      "브리지 미실행 시 실행 명령 안내",
    ],
  ),
  HistoryEntry(
    version: "0.4.8",
    date: "2026-07-23",
    lines: <String>[
      "기권 시 상대 승으로 계가/결과 표시",
      "멀티 기권 메시지에 기권자 반영",
      "기권승 라벨 (다국어)",
    ],
  ),
  HistoryEntry(
    version: "0.4.7",
    date: "2026-07-23",
    lines: <String>[
      "홈에 버전 배지 표시",
      "착수 스크린리더 낭독 (aria-live)",
      "scripts/dev-all.ps1 — 브리지+개발서버 동시 실행",
    ],
  ),
  HistoryEntry(
    version: "0.4.6",
    date: "2026-07-23",
    lines: <String>[
      "혼자 두기: AI 힌트(추천 수 마커)",
      "KataGo 연결 시 GTP, 아니면 내장 AI",
      "힌트 후 착수하면 마커 자동 제거",
    ],
  ),
  HistoryEntry(
    version: "0.4.5",
    date: "2026-07-23",
    lines: <String>[
      "학습 레슨·따냄 연습 ja/zh/vi 추가 (5개 언어)",
      "배우기 탭 라벨 다국어",
      "로컬라이즈 단위 테스트",
    ],
  ),
  HistoryEntry(
    version: "0.4.4",
    date: "2026-07-23",
    lines: <String>[
      "학습 레슨·따냄 연습 영어 로컬라이즈",
      "KataGo 브리지 health: OS/arch·exe/model 존재 표시",
      "모델 없을 때 연결 전 안내",
    ],
  ),
  HistoryEntry(
    version: "0.4.3",
    date: "2026-07-23",
    lines: <String>[
      "위치 슈퍼코: 과거와 같은 바둑판 재현 착수 금지",
      "패/슈퍼코 안내 문구 분리",
      "엔진 테스트에 슈퍼코 케이스 추가",
    ],
  ),
  HistoryEntry(
    version: "0.4.2",
    date: "2026-07-23",
    lines: <String>[
      "GitHub Actions CI (test+build)",
      "gh-pages 배포 스크립트 (npm run deploy)",
      "따냄 연습 5제 · 브리지 health에 플랫폼/파일 존재 여부",
    ],
  ),
  HistoryEntry(
    version: "0.4.1",
    date: "2026-07-23",
    lines: <String>[
      "대국 종료 시 집 영역 보드 표시(흑집/백집 라벨)",
      "복기 단축키 Z/X (보드 착수 화살표와 분리)",
      "멀티 종료 시에도 집 표시",
    ],
  ),
  HistoryEntry(
    version: "0.4.0",
    date: "2026-07-23",
    lines: <String>[
      "SGF 기보 저장·불러오기",
      "혼자 두기: 한 수 뒤/앞으로 복기",
      "설정·대국 패널에서 기보 파일 선택",
    ],
  ),
  HistoryEntry(
    version: "0.3.0",
    date: "2026-07-23",
    lines: <String>[
      "KataGo 로컬 HTTP 브리지 (npm run katago:bridge)",
      "설정: 브리지 URL·exe/model/config·자동 연결",
      "급단 visits → maxVisits GTP 힌트",
    ],
  ),
  HistoryEntry(
    version: "0.2.2",
    date: "2026-07-23",
    lines: <String>[
      "착수 소리 on/off (Web Audio)",
      "돌·칸 크기 / 선 굵기 3단계 설정",
      "설정에서 소리 미리듣기",
    ],
  ),
  HistoryEntry(
    version: "0.2.1",
    date: "2026-07-23",
    lines: <String>[
      "초보 계가: 집+사석+덤 (대국 종료 시 표시)",
      "공배(양쪽 접촉)는 미확정으로 처리",
      "계가 단위 테스트 추가",
    ],
  ),
  HistoryEntry(
    version: "0.2.0",
    date: "2026-07-23",
    lines: <String>[
      "배우기: 따냄 연습 문제 4제 + 보드 연동",
      "멀티: 방 ID QR 코드 표시",
      "문제 정답 마커·힌트·다시 풀기",
    ],
  ),
  HistoryEntry(
    version: "0.1.1",
    date: "2026-07-23",
    lines: <String>[
      "엔진 패(劫) 단위 테스트 추가",
      "P2P: 연결 타임아웃·실패 안내, 끊김 시 로비 복귀",
      "연결 다시 준비 버튼·다국어 오류 문구",
    ],
  ),
  HistoryEntry(
    version: "0.1.0",
    date: "2026-07-23",
    lines: <String>[
      "고대비 바둑 MVP 골격 (React + Vite)",
      "단계별 배우기 / 혼자서 두기(급·단) / P2P 멀티",
      "착수점 깜빡임·키보드 착수·KataGo GTP 스텁",
    ],
  ),
];
