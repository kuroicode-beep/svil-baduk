// lib/domain/engine/gtp_coord.dart — GTP 좌표 ↔ 판 좌표
//
// GTP 는 사람이 읽는 좌표계와 같다: 열은 I 를 건너뛴 A~T, 행은 **아래가 1**.
// 우리 판 좌표는 y=0 이 위다. 그래서 변환에 뒤집기가 들어간다.
//
// ⚠ 이 뒤집기가 React 판에서 조용히 두 번 일어났었다. pointLabel 이
// 잘못 뒤집혀 있었고 파싱이 그 정확한 역함수여서, 두 오류가 서로를 가려
// KataGo 가 거울 판에서 두는데도 좌표는 맞아 보였다. 왕복 테스트만으로는
// 못 잡는다 — 반드시 알려진 값(19줄 좌상 화점 = D16)으로 고정한다.

import 'types.dart';

const String _gtpLetters = 'ABCDEFGHJKLMNOPQRST';

/// 판 좌표 → GTP 문자열 (예: 19줄에서 (3,3) → 'D16')
String toGtpCoord(int x, int y, int lines) =>
    '${_gtpLetters[x]}${lines - y}';

/// GTP 문자열 → 판 좌표. 'pass'/'resign' 과 해석 실패는 null.
Point? parseGtpCoord(String raw, int lines) {
  final String s = raw.trim().toUpperCase();
  if (s.isEmpty || s == 'PASS' || s == 'RESIGN') return null;

  final int x = _gtpLetters.indexOf(s[0]);
  if (x < 0 || x >= lines) return null;

  final int? num = int.tryParse(s.substring(1));
  if (num == null || num < 1 || num > lines) return null;

  return Point(x, lines - num);
}

/// 'pass' 응답인지 — null 과 구별해야 패스와 오류가 섞이지 않는다
bool isGtpPass(String raw) => raw.trim().toUpperCase() == 'PASS';

bool isGtpResign(String raw) => raw.trim().toUpperCase() == 'RESIGN';

/// 착수 명령 한 줄
String gtpPlayCommand(Move m, int lines) {
  final String color = m.player == Stone.black ? 'B' : 'W';
  final String where = m.isPass ? 'pass' : toGtpCoord(m.x, m.y, lines);
  return 'play $color $where';
}
