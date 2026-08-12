// lib/domain/engine/types.dart — 바둑 엔진 핵심 타입 (순수 Dart)
//
// 와이어 값(0 빈 점, 1 흑, 2 백)은 React 판과 동일하게 유지한다.
// SGF·백업·차분 테스트가 이 값에 의존한다.

import 'dart:typed_data';

enum Stone {
  empty(0),
  black(1),
  white(2);

  const Stone(this.wire);
  final int wire;

  static Stone fromWire(int v) => switch (v) {
        1 => Stone.black,
        2 => Stone.white,
        _ => Stone.empty,
      };

  Stone get opponent => switch (this) {
        Stone.black => Stone.white,
        Stone.white => Stone.black,
        Stone.empty => Stone.empty,
      };
}

/// 착수하는 쪽 — Stone.empty 는 올 수 없다
typedef Player = Stone;

enum BoardSize {
  s9(9),
  s13(13),
  s19(19);

  const BoardSize(this.lines);
  final int lines;

  static BoardSize fromLines(int n) => switch (n) {
        9 => BoardSize.s9,
        13 => BoardSize.s13,
        19 => BoardSize.s19,
        _ => throw ArgumentError('지원하지 않는 판 크기: $n'),
      };
}

class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

class Move {
  const Move({
    required this.player,
    required this.x,
    required this.y,
    this.isPass = false,
    this.captured = const <Point>[],
  });

  const Move.pass(this.player)
      : x = -1,
        y = -1,
        isPass = true,
        captured = const <Point>[];

  final Player player;
  final int x;
  final int y;
  final bool isPass;
  final List<Point> captured;

  Point get point => Point(x, y);
}

/// 착수가 거부된 이유 — UI 가 사유별로 다른 문장을 낭독한다
enum MoveError {
  gameEnded,
  outOfBounds,
  occupied,
  ko,
  superko,
  suicide;

  /// React 판의 reason 문자열과 대응 (차분 테스트용)
  String get wire => switch (this) {
        MoveError.gameEnded => 'game_ended',
        MoveError.outOfBounds => 'oob',
        MoveError.occupied => 'occupied',
        MoveError.ko => 'ko',
        MoveError.superko => 'superko',
        MoveError.suicide => 'suicide',
      };
}

sealed class PlayResult {
  const PlayResult();
  bool get ok => this is PlayOk;
}

final class PlayOk extends PlayResult {
  const PlayOk(this.state, this.move);
  final GameState state;
  final Move move;
}

final class PlayErr extends PlayResult {
  const PlayErr(this.error);
  final MoveError error;
}

/// 불변 게임 상태.
///
/// React 판과 다른 점: positionHashes 문자열 배열이 없다.
/// 슈퍼코는 Zobrist 정수 해시 집합으로 처리하고 **저장하지 않는다** —
/// 불러올 때 history 에서 다시 만든다(그쪽이 이미 정본 경로였다).
class GameState {
  GameState({
    required this.size,
    required this.board,
    required this.initialBoard,
    required this.toPlay,
    required this.blackCaptures,
    required this.whiteCaptures,
    required this.history,
    required this.koPoint,
    required this.consecutivePasses,
    required this.ended,
    required this.resignedBy,
    required this.zobrist,
  });

  final BoardSize size;

  /// Stone.wire 값을 담은 평면 배열 (y * lines + x)
  final Uint8List board;

  /// 이 대국이 시작된 위치. 보통 빈 판이지만 배치 문제·접바둑에서는 돌이 있다.
  /// 슈퍼코 집합을 다시 만들 때 history 만으로는 복원할 수 없어서 필요하다.
  final Uint8List initialBoard;
  final Player toPlay;
  final int blackCaptures;
  final int whiteCaptures;
  final List<Move> history;
  final Point? koPoint;
  final int consecutivePasses;
  final bool ended;
  final Player? resignedBy;

  /// 현재 판 위치의 Zobrist 해시
  final int zobrist;

  int get lines => size.lines;

  Stone stoneAt(int x, int y) => Stone.fromWire(board[y * lines + x]);

  int capturesOf(Player p) => p == Stone.black ? blackCaptures : whiteCaptures;

  GameState copyWith({
    Uint8List? board,
    Player? toPlay,
    int? blackCaptures,
    int? whiteCaptures,
    List<Move>? history,
    Point? koPoint,
    bool clearKo = false,
    int? consecutivePasses,
    bool? ended,
    Player? resignedBy,
    int? zobrist,
  }) =>
      GameState(
        size: size,
        board: board ?? this.board,
        initialBoard: initialBoard,
        toPlay: toPlay ?? this.toPlay,
        blackCaptures: blackCaptures ?? this.blackCaptures,
        whiteCaptures: whiteCaptures ?? this.whiteCaptures,
        history: history ?? this.history,
        koPoint: clearKo ? null : (koPoint ?? this.koPoint),
        consecutivePasses: consecutivePasses ?? this.consecutivePasses,
        ended: ended ?? this.ended,
        resignedBy: resignedBy ?? this.resignedBy,
        zobrist: zobrist ?? this.zobrist,
      );
}
