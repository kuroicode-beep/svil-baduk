// lib/domain/engine/board.dart — 바둑 규칙 엔진 (순수 Dart)
//
// src/engine/board.ts 를 이식했다. 규칙은 동일하다:
// 따냄 → 자살수 금지 → 단순 패 → 위치 초과(positional superko).
// 따냄을 먼저 처리하므로 "따내면서 두는 수"는 자살수가 아니다.

import 'dart:typed_data';

import 'types.dart';
import 'zobrist.dart';

/// 슈퍼코 판정용 위치 집합 캐시.
/// React 판의 `WeakMap<GameState, Set>` 과 같은 역할 — Dart 에서는 Expando 다.
/// legalMoves 가 같은 state 로 n² 번 tryPlay 를 부르는데, 집합은 한 번만 만든다.
final Expando<Set<int>> _seenCache = Expando<Set<int>>();

Set<int> _seen(GameState s) {
  Set<int>? set = _seenCache[s];
  if (set == null) {
    set = _rebuildSeen(s);
    _seenCache[s] = set;
  }
  return set;
}

/// history 를 재생해 지나온 위치 해시를 모은다.
/// 저장된 값을 믿지 않는 것이 원칙이다 (형식이 바뀌어도 안전).
Set<int> _rebuildSeen(GameState s) {
  final Set<int> out = <int>{};
  final int lines = s.lines;
  // 빈 판이 아니라 **시작 위치**에서 재생한다.
  // 배치 문제는 history 가 비어 있고 판에 돌이 있어서, 빈 판에서 재생하면
  // 배치 위치가 통째로 빠지고 슈퍼코가 그 위치를 못 잡는다.
  final Uint8List b = Uint8List.fromList(s.initialBoard);
  out.add(Zobrist.ofBoard(b, lines));

  GameState cur = GameState(
    size: s.size,
    board: b,
    initialBoard: s.initialBoard,
    toPlay: s.history.isNotEmpty ? s.history.first.player : Stone.black,
    blackCaptures: 0,
    whiteCaptures: 0,
    history: const <Move>[],
    koPoint: null,
    consecutivePasses: 0,
    ended: false,
    resignedBy: null,
    zobrist: Zobrist.ofBoard(b, lines),
  );
  _seenCache[cur] = out;
  for (final Move m in s.history) {
    final PlayResult r = m.isPass ? passMove(cur) : tryPlay(cur, m.x, m.y);
    if (r is! PlayOk) break;
    cur = r.state;
    out.add(cur.zobrist);
  }
  return out;
}

int _idx(int lines, int x, int y) => y * lines + x;

bool inBounds(int lines, int x, int y) =>
    x >= 0 && y >= 0 && x < lines && y < lines;

GameState createGame(BoardSize size) {
  final Uint8List board = Uint8List(size.lines * size.lines);
  final GameState g = GameState(
    size: size,
    board: board,
    initialBoard: board,
    toPlay: Stone.black,
    blackCaptures: 0,
    whiteCaptures: 0,
    history: const <Move>[],
    koPoint: null,
    consecutivePasses: 0,
    ended: false,
    resignedBy: null,
    zobrist: 0,
  );
  _seenCache[g] = <int>{0};
  return g;
}

/// 배치 문제용 — 돌을 "놓는" 게 아니라 "설치"한다.
/// 따냄·자살수 검사·차례 전환이 없고, 해시는 배치 완료 후 계산한다.
/// (React 판에서 이 해시 시딩이 빠져 있어 슈퍼코가 틀어졌던 적이 있다)
GameState createProblemState({
  required BoardSize size,
  required List<Point> black,
  required List<Point> white,
  required Player toPlay,
}) {
  final int lines = size.lines;
  final Uint8List board = Uint8List(lines * lines);
  for (final Point p in black) {
    board[_idx(lines, p.x, p.y)] = Stone.black.wire;
  }
  for (final Point p in white) {
    board[_idx(lines, p.x, p.y)] = Stone.white.wire;
  }
  final int hash = Zobrist.ofBoard(board, lines);
  final GameState g = GameState(
    size: size,
    board: board,
    initialBoard: board,
    toPlay: toPlay,
    blackCaptures: 0,
    whiteCaptures: 0,
    history: const <Move>[],
    koPoint: null,
    consecutivePasses: 0,
    ended: false,
    resignedBy: null,
    zobrist: hash,
  );
  // 배치 위치도 "지나온 위치"다 — 이걸 빠뜨리면 슈퍼코가 배치 위치를 못 잡는다
  _seenCache[g] = <int>{hash};
  return g;
}

class _Group {
  _Group(this.stones, this.libertyPoints);
  final List<int> stones;

  /// 활로의 위치. 개수만 쓰던 것을 위치까지 남기게 바꿨다 —
  /// 어차피 계산 중에 만들던 집합이라 비용은 그대로다.
  final Set<int> libertyPoints;

  int get liberties => libertyPoints.length;
}

/// 이어진 돌 무리와 활로 수 — 평면 인덱스로 다룬다
_Group _groupAt(Uint8List board, int lines, int start) {
  final int color = board[start];
  if (color == 0) return _Group(const <int>[], const <int>{});

  final List<int> stones = <int>[];
  final Set<int> seenStone = <int>{};
  final Set<int> libs = <int>{};
  final List<int> stack = <int>[start];

  while (stack.isNotEmpty) {
    final int i = stack.removeLast();
    if (!seenStone.add(i)) continue;
    stones.add(i);
    final int x = i % lines;
    final int y = i ~/ lines;

    if (x > 0) _visit(board, lines, i - 1, color, seenStone, libs, stack);
    if (x < lines - 1) _visit(board, lines, i + 1, color, seenStone, libs, stack);
    if (y > 0) _visit(board, lines, i - lines, color, seenStone, libs, stack);
    if (y < lines - 1) _visit(board, lines, i + lines, color, seenStone, libs, stack);
  }
  return _Group(stones, libs);
}

void _visit(Uint8List board, int lines, int n, int color, Set<int> seenStone,
    Set<int> libs, List<int> stack) {
  final int v = board[n];
  if (v == 0) {
    libs.add(n);
  } else if (v == color && !seenStone.contains(n)) {
    stack.add(n);
  }
}

PlayResult tryPlay(GameState state, int x, int y) {
  if (state.ended) return const PlayErr(MoveError.gameEnded);
  final int lines = state.lines;
  if (!inBounds(lines, x, y)) return const PlayErr(MoveError.outOfBounds);
  final int at = _idx(lines, x, y);
  if (state.board[at] != 0) return const PlayErr(MoveError.occupied);
  if (state.koPoint != null && state.koPoint!.x == x && state.koPoint!.y == y) {
    return const PlayErr(MoveError.ko);
  }

  final Player player = state.toPlay;
  final Stone opp = player.opponent;
  final Uint8List next = Uint8List.fromList(state.board);
  next[at] = player.wire;
  int hash = Zobrist.toggle(state.zobrist, lines, x, y, player);

  // 1) 상대 돌부터 따낸다 — 따내는 수는 자살수가 아니게 된다
  final List<Point> captured = <Point>[];
  for (final int n in _neighbours(lines, at)) {
    if (next[n] != opp.wire) continue;
    final _Group g = _groupAt(next, lines, n);
    if (g.liberties != 0) continue;
    for (final int s in g.stones) {
      next[s] = 0;
      final int cx = s % lines;
      final int cy = s ~/ lines;
      captured.add(Point(cx, cy));
      hash = Zobrist.toggle(hash, lines, cx, cy, opp);
    }
  }

  // 2) 자기 무리가 활로 0 이면 자살수
  if (_groupAt(next, lines, at).liberties == 0) {
    return const PlayErr(MoveError.suicide);
  }

  // 3) 위치 초과 — 지나온 위치를 다시 만들 수 없다
  if (_seen(state).contains(hash)) {
    return const PlayErr(MoveError.superko);
  }

  // 4) 단순 패: 한 점만 따냈고 그 결과 내 돌이 홀로 활로 1 이면 되따냄 금지
  Point? koPoint;
  if (captured.length == 1) {
    final _Group after = _groupAt(next, lines, at);
    if (after.stones.length == 1 && after.liberties == 1) {
      koPoint = captured.first;
    }
  }

  final Move move = Move(player: player, x: x, y: y, captured: captured);
  final GameState result = GameState(
    size: state.size,
    board: next,
    initialBoard: state.initialBoard,
    toPlay: opp,
    blackCaptures:
        state.blackCaptures + (player == Stone.black ? captured.length : 0),
    whiteCaptures:
        state.whiteCaptures + (player == Stone.white ? captured.length : 0),
    history: <Move>[...state.history, move],
    koPoint: koPoint,
    consecutivePasses: 0,
    ended: false,
    resignedBy: null,
    zobrist: hash,
  );
  // 다음 상태의 위치 집합을 미리 채워 둔다 (재생 비용 회피)
  _seenCache[result] = <int>{..._seen(state), hash};
  return PlayOk(result, move);
}

Iterable<int> _neighbours(int lines, int i) sync* {
  final int x = i % lines;
  final int y = i ~/ lines;
  if (x > 0) yield i - 1;
  if (x < lines - 1) yield i + 1;
  if (y > 0) yield i - lines;
  if (y < lines - 1) yield i + lines;
}

PlayResult passMove(GameState state) {
  if (state.ended) return const PlayErr(MoveError.gameEnded);
  final Move move = Move.pass(state.toPlay);
  final int passes = state.consecutivePasses + 1;
  final GameState next = GameState(
    size: state.size,
    board: state.board,
    initialBoard: state.initialBoard,
    toPlay: state.toPlay.opponent,
    blackCaptures: state.blackCaptures,
    whiteCaptures: state.whiteCaptures,
    history: <Move>[...state.history, move],
    koPoint: null,
    consecutivePasses: passes,
    ended: passes >= 2,
    resignedBy: null,
    zobrist: state.zobrist,
  );
  _seenCache[next] = _seen(state);
  return PlayOk(next, move);
}

GameState resign(GameState state, Player player) => state.copyWith(
      ended: true,
      resignedBy: player,
    );

List<Point> legalMoves(GameState state) {
  final List<Point> out = <Point>[];
  final int lines = state.lines;
  for (int y = 0; y < lines; y++) {
    for (int x = 0; x < lines; x++) {
      if (state.board[_idx(lines, x, y)] != 0) continue;
      if (tryPlay(state, x, y).ok) out.add(Point(x, y));
    }
  }
  return out;
}

/// history 를 처음부터 재생 — 저장된 board 를 믿지 않는 정본 계산
GameState replayHistory(BoardSize size, List<Move> history) {
  GameState cur = createGame(size);
  if (history.isNotEmpty && history.first.player != Stone.black) {
    cur = cur.copyWith(toPlay: history.first.player);
  }
  for (final Move m in history) {
    final PlayResult r = m.isPass ? passMove(cur) : tryPlay(cur, m.x, m.y);
    if (r is! PlayOk) break;
    cur = r.state;
  }
  return cur;
}

const String _columnLetters = 'ABCDEFGHJKLMNOPQRST';

/// 사람이 읽는 좌표 — A1 이 좌하단(표준 바둑·GTP).
/// board 배열은 y=0 이 위쪽이라 세로를 뒤집는다. SGF 는 뒤집지 않는다.
String pointLabel(int x, int y, int lines) =>
    '${_columnLetters[x]}${lines - y}';

/// 지금 두는 쪽이 두면 돌을 따내게 되는 점들.
///
/// 후보는 "상대 그룹의 마지막 활로" 뿐이라 O(판 크기) 로 찾는다.
/// 다만 그 점이 패 금지점이거나 슈퍼코에 걸리면 둘 수 없으므로
/// 후보만 실제로 확인한다 — 후보 수는 축에 걸린 그룹 수뿐이다.
/// (전 합법수를 두어 보는 방식과 결과가 같다: capture_points_test.dart)
Set<Point> capturePoints(GameState state) {
  final int lines = state.size.lines;
  final int enemy = state.toPlay.opponent.wire;
  final Set<int> seen = <int>{};
  final Set<Point> out = <Point>{};

  for (int i = 0; i < state.board.length; i++) {
    if (state.board[i] != enemy || seen.contains(i)) continue;
    final _Group g = _groupAt(state.board, lines, i);
    seen.addAll(g.stones);
    if (g.liberties != 1) continue;

    final int lib = g.libertyPoints.first;
    final Point p = Point(lib % lines, lib ~/ lines);
    // 활로를 메우는 수는 자살이 될 수 없지만 패·슈퍼코에는 걸린다
    if (tryPlay(state, p.x, p.y) is PlayOk) out.add(p);
  }
  return out;
}

List<Point> starPoints(BoardSize size) => switch (size) {
      BoardSize.s9 => const <Point>[
          Point(2, 2), Point(6, 2), Point(4, 4), Point(2, 6), Point(6, 6),
        ],
      BoardSize.s13 => const <Point>[
          Point(3, 3), Point(9, 3), Point(6, 6), Point(3, 9), Point(9, 9),
        ],
      BoardSize.s19 => const <Point>[
          Point(3, 3), Point(9, 3), Point(15, 3),
          Point(3, 9), Point(9, 9), Point(15, 9),
          Point(3, 15), Point(9, 15), Point(15, 15),
        ],
    };
