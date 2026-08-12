// lib/domain/engine/zobrist.dart — 위치 해시
//
// React 판은 판을 문자열로 패킹해 positionHashes 배열에 쌓고
// Array.includes 로 훑었다. Dart 에서는 정수 해시 + Set 으로 바꾼다.
//
// 시드는 고정 상수다. 실행마다 값이 같아야 테스트가 재현되고,
// 저장된 기보를 다시 열었을 때도 같은 해시가 나온다.

import 'dart:typed_data';

import 'types.dart';

abstract final class Zobrist {
  /// 19×19×2 (돌 종류 2개) — 작은 판은 앞부분만 쓴다
  static final Int64List _table = _buildTable();

  /// 임의의 고정 시드. 값 자체는 의미가 없지만 **절대 바꾸지 말 것** —
  /// 바뀌면 저장된 기보의 슈퍼코 판정이 달라진다.
  static const int _seed = 0x5D8BADC0DE5EED;
  static const int _maxLines = 19;

  static Int64List _buildTable() {
    final Int64List t = Int64List(_maxLines * _maxLines * 2);
    int s = _seed;
    for (int i = 0; i < t.length; i++) {
      // xorshift64 — 결정적이고 분포가 충분하다
      s ^= s << 13;
      s ^= s >>> 7;
      s ^= s << 17;
      t[i] = s;
    }
    return t;
  }

  /// 해당 교차점에 그 색 돌이 놓인/치워진 것을 해시에 반영 (XOR 이라 자기역원)
  static int toggle(int hash, int lines, int x, int y, Stone stone) {
    assert(stone != Stone.empty, '빈 점은 해시에 넣지 않는다');
    final int idx = ((y * _maxLines + x) * 2) + (stone == Stone.black ? 0 : 1);
    return hash ^ _table[idx];
  }

  /// 판 전체에서 해시를 처음부터 계산 (배치 문제·불러오기용)
  static int ofBoard(Uint8List board, int lines) {
    int h = 0;
    for (int y = 0; y < lines; y++) {
      for (int x = 0; x < lines; x++) {
        final Stone s = Stone.fromWire(board[y * lines + x]);
        if (s != Stone.empty) h = toggle(h, lines, x, y, s);
      }
    }
    return h;
  }
}
