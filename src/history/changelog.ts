export interface HistoryEntry {
  version: string
  date: string
  lines: string[]
}

export const CHANGELOG: HistoryEntry[] = [
  {
    version: '0.7.2',
    date: '2026-07-24',
    lines: [
      '흑/백 돌 색 선택 (설정) · 상대 직전 수 내 착수까지 깜빡임',
      '우측 패널: 직전 좌표 확대 · 진행 중 집/합계 표시',
      'AI 대국 스냅샷 — 종료 후에도 이어서 두기',
    ],
  },
  {
    version: '0.7.1',
    date: '2026-07-24',
    lines: [
      'AI 첫 수가 영구 대기하던 버그 수정 (aiBusy effect 자기취소)',
      'KataGo genmove 실패 시 내장 AI로 즉시 폴백',
    ],
  },
  {
    version: '0.7.0',
    date: '2026-07-23',
    lines: [
      'Stitch 고대비 비전 UI (홈 2열·버튼·설정 미리보기·Solo/멀티/캐릭터)',
      'KataGo GPU(RTX 5060 Ti): 증분 보드 동기화·스레드/시간 상한',
      '서버 콘솔 숨김 실행 · 버튼 대비 확실하게 옵션 · 화점 고대비 표시',
    ],
  },
  {
    version: '0.6.9',
    date: '2026-07-23',
    lines: [
      '설정: 버튼 대비 확실하게 옵션 (글자·테두리 강화)',
      '서버/브리지 콘솔 백그라운드(숨김) 실행',
      'Stitch 접근성 비전 디자인 적용 (홈 2열·버튼 시스템·설정 미리보기)',
      'KataGo: 보드 증분 동기화 + RTX 5060 Ti용 스레드/시간 상한 (체감 속도)',
    ],
  },
  {
    version: '0.6.8',
    date: '2026-07-23',
    lines: [
      '대국 시작 시 전체화면',
      '바둑판·메뉴 한 화면 맞춤 정렬 (보드 잘림/스크롤 제거)',
    ],
  },
  {
    version: '0.6.7',
    date: '2026-07-23',
    lines: [
      'Tauri 2 데스크톱 셸 (npm run tauri:dev / tauri:build)',
      'Windows Authenticode 코드사인 훅 (인증서 있을 때 자동 서명)',
      '바탕화면 바로가기: shortcut:tauri',
    ],
  },
  {
    version: '0.6.6',
    date: '2026-07-23',
    lines: [
      'package.json homepage (GitHub Pages URL)',
      '로드맵: 배포 파이프라인 상태 갱신',
    ],
  },
  {
    version: '0.6.5',
    date: '2026-07-23',
    lines: [
      'AI 대국: 난이도·판 크기·색깔 선택 기억',
    ],
  },
  {
    version: '0.6.4',
    date: '2026-07-23',
    lines: [
      'README·Outline 로컬 위키를 0.6.x 기능에 맞춤',
      '배포/Pages·캐릭터·AI 대국 안내 정리',
    ],
  },
  {
    version: '0.6.3',
    date: '2026-07-23',
    lines: [
      '포커스 링 #FFFF00 (고대비 표준)',
      'AI 힌트 단축키 H + 스크린리더 후보 낭독',
    ],
  },
  {
    version: '0.6.2',
    date: '2026-07-23',
    lines: [
      'AI 힌트: 상위 3수 숫자·상대점수 라벨 (분석 색칠 1차)',
      'KataGo 연결 시 1순위 AI 수 + 보조 후보 표시',
    ],
  },
  {
    version: '0.6.1',
    date: '2026-07-23',
    lines: [
      '설정: 일본식/중국식 룰 + 덤 계가 분기',
      '바로가기 런처 안정화 (포트 재사용·ASCII BOM)',
    ],
  },
  {
    version: '0.6.0',
    date: '2026-07-23',
    lines: [
      '유저 캐릭터 생성(이름·상징)',
      '레벨업·XP, 전적(W/L/D), 최고 점수·최고 격파 난이도',
      'AI 대국 종료 시 프로필 반영',
    ],
  },
  {
    version: '0.5.3',
    date: '2026-07-23',
    lines: [
      '설정: GPU/CPU 추정 안내 (WebGPU·WebGL)',
      '엔진 테스트: 자살수·따냄 케이스 추가',
    ],
  },
  {
    version: '0.5.2',
    date: '2026-07-23',
    lines: [
      'AI 난이도 10단계(1 입문 ~ 10 고수)로 통일',
      '바탕화면 바로가기 스크립트 (start-app / install_desktop_shortcut)',
    ],
  },
  {
    version: '0.5.1',
    date: '2026-07-23',
    lines: [
      'KataGo 로컬 설치 스크립트 (npm run katago:setup)',
      '브리지 기본 설정 gtp_play.cfg · 시작 시 자동연결 재시도',
      'OpenCL 바이너리 + g170e b20 모델 배치 안내',
    ],
  },
  {
    version: '0.5.0',
    date: '2026-07-23',
    lines: [
      '핵심 모드 명확화: AI와 겨루기 (난이도·급단 선택)',
      '홈 첫 CTA로 AI 대국 배치 + 안내 문구',
      '설정: 입문/초급/중급/고급 난이도 밴드 + 급단',
    ],
  },
  {
    version: '0.4.9',
    date: '2026-07-23',
    lines: [
      '혼자 두기: 엔진 표시 (내장 휴리스틱 / KataGo visits)',
      '급단 목록에 visits 병기 (KataGo 연결 시)',
      '브리지 미실행 시 실행 명령 안내',
    ],
  },
  {
    version: '0.4.8',
    date: '2026-07-23',
    lines: [
      '기권 시 상대 승으로 계가/결과 표시',
      '멀티 기권 메시지에 기권자 반영',
      '기권승 라벨 (다국어)',
    ],
  },
  {
    version: '0.4.7',
    date: '2026-07-23',
    lines: [
      '홈에 버전 배지 표시',
      '착수 스크린리더 낭독 (aria-live)',
      'scripts/dev-all.ps1 — 브리지+개발서버 동시 실행',
    ],
  },
  {
    version: '0.4.6',
    date: '2026-07-23',
    lines: [
      '혼자 두기: AI 힌트(추천 수 마커)',
      'KataGo 연결 시 GTP, 아니면 내장 AI',
      '힌트 후 착수하면 마커 자동 제거',
    ],
  },
  {
    version: '0.4.5',
    date: '2026-07-23',
    lines: [
      '학습 레슨·따냄 연습 ja/zh/vi 추가 (5개 언어)',
      '배우기 탭 라벨 다국어',
      '로컬라이즈 단위 테스트',
    ],
  },
  {
    version: '0.4.4',
    date: '2026-07-23',
    lines: [
      '학습 레슨·따냄 연습 영어 로컬라이즈',
      'KataGo 브리지 health: OS/arch·exe/model 존재 표시',
      '모델 없을 때 연결 전 안내',
    ],
  },
  {
    version: '0.4.3',
    date: '2026-07-23',
    lines: [
      '위치 슈퍼코: 과거와 같은 바둑판 재현 착수 금지',
      '패/슈퍼코 안내 문구 분리',
      '엔진 테스트에 슈퍼코 케이스 추가',
    ],
  },
  {
    version: '0.4.2',
    date: '2026-07-23',
    lines: [
      'GitHub Actions CI (test+build)',
      'gh-pages 배포 스크립트 (npm run deploy)',
      '따냄 연습 5제 · 브리지 health에 플랫폼/파일 존재 여부',
    ],
  },
  {
    version: '0.4.1',
    date: '2026-07-23',
    lines: [
      '대국 종료 시 집 영역 보드 표시(흑집/백집 라벨)',
      '복기 단축키 Z/X (보드 착수 화살표와 분리)',
      '멀티 종료 시에도 집 표시',
    ],
  },
  {
    version: '0.4.0',
    date: '2026-07-23',
    lines: [
      'SGF 기보 저장·불러오기',
      '혼자 두기: 한 수 뒤/앞으로 복기',
      '설정·대국 패널에서 기보 파일 선택',
    ],
  },
  {
    version: '0.3.0',
    date: '2026-07-23',
    lines: [
      'KataGo 로컬 HTTP 브리지 (npm run katago:bridge)',
      '설정: 브리지 URL·exe/model/config·자동 연결',
      '급단 visits → maxVisits GTP 힌트',
    ],
  },
  {
    version: '0.2.2',
    date: '2026-07-23',
    lines: [
      '착수 소리 on/off (Web Audio)',
      '돌·칸 크기 / 선 굵기 3단계 설정',
      '설정에서 소리 미리듣기',
    ],
  },
  {
    version: '0.2.1',
    date: '2026-07-23',
    lines: [
      '초보 계가: 집+사석+덤 (대국 종료 시 표시)',
      '공배(양쪽 접촉)는 미확정으로 처리',
      '계가 단위 테스트 추가',
    ],
  },
  {
    version: '0.2.0',
    date: '2026-07-23',
    lines: [
      '배우기: 따냄 연습 문제 4제 + 보드 연동',
      '멀티: 방 ID QR 코드 표시',
      '문제 정답 마커·힌트·다시 풀기',
    ],
  },
  {
    version: '0.1.1',
    date: '2026-07-23',
    lines: [
      '엔진 패(劫) 단위 테스트 추가',
      'P2P: 연결 타임아웃·실패 안내, 끊김 시 로비 복귀',
      '연결 다시 준비 버튼·다국어 오류 문구',
    ],
  },
  {
    version: '0.1.0',
    date: '2026-07-23',
    lines: [
      '고대비 바둑 MVP 골격 (React + Vite)',
      '단계별 배우기 / 혼자서 두기(급·단) / P2P 멀티',
      '착수점 깜빡임·키보드 착수·KataGo GTP 스텁',
    ],
  },
]
