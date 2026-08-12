// lib/domain/engine/snapshot.dart — 진행 중 대국 저장·복원
//
// 판을 통째로 저장하지 않고 초기 배치 + 수순만 저장한다. 그러면 복원할 때
// 엔진이 재생하면서 따냄·패·슈퍼코 집합을 스스로 다시 만든다.
// 판만 저장하면 슈퍼코 이력이 사라져 복원 직후 반칙 판정이 달라진다.

import 'dart:convert';

import 'board.dart';
import 'types.dart';

/// 저장 형식 버전. 구조가 바뀌면 올리고 아래 마이그레이션에 분기를 더한다.
const int kSnapshotVersion = 1;

sealed class SnapshotResult {
  const SnapshotResult();
}

final class SnapshotOk extends SnapshotResult {
  const SnapshotOk(this.state);
  final GameState state;
}

final class SnapshotFail extends SnapshotResult {
  const SnapshotFail(this.reasonKey, {this.detail});

  /// i18n 키 — 사용자에게 보일 문구를 여기서 만들지 않는다
  final String reasonKey;
  final String? detail;
}

Map<String, Object?> snapshotToJson(GameState s) => <String, Object?>{
      'version': kSnapshotVersion,
      'size': s.size.lines,
      // 배치 문제에서 이어 두는 경우가 있어 초기 판도 남긴다
      'initial': s.initialBoard.toList(),
      'moves': <Map<String, Object?>>[
        for (final Move m in s.history)
          <String, Object?>{
            'p': m.player.wire,
            if (m.isPass) 'pass': true else 'x': m.x, if (!m.isPass) 'y': m.y,
          },
      ],
      'resignedBy': s.resignedBy?.wire,
    };

String encodeSnapshot(GameState s) => jsonEncode(snapshotToJson(s));

SnapshotResult decodeSnapshot(String text) {
  final Object? raw;
  try {
    raw = jsonDecode(text);
  } on FormatException catch (e) {
    return SnapshotFail('snapshotCorrupt', detail: e.message);
  }
  if (raw is! Map<String, Object?>) {
    return const SnapshotFail('snapshotCorrupt');
  }

  final Object? version = raw['version'];
  if (version is! int) return const SnapshotFail('snapshotCorrupt');
  if (version > kSnapshotVersion) {
    // 앞으로 나온 형식은 추측해서 읽지 않는다 — 대국을 망치느니 거절한다
    return SnapshotFail('snapshotTooNew', detail: '$version');
  }

  final Object? lines = raw['size'];
  if (lines is! int || (lines != 9 && lines != 13 && lines != 19)) {
    return SnapshotFail('snapshotBadSize', detail: '$lines');
  }
  final BoardSize size = BoardSize.fromLines(lines);

  final Object? moves = raw['moves'];
  if (moves is! List) return const SnapshotFail('snapshotCorrupt');

  // 초기 배치 복원 (없으면 빈 판 — 형식 1 이전 데이터 호환)
  final List<Point> black = <Point>[];
  final List<Point> white = <Point>[];
  final Object? initial = raw['initial'];
  if (initial is List) {
    if (initial.length != lines * lines) {
      return const SnapshotFail('snapshotCorrupt');
    }
    for (int i = 0; i < initial.length; i++) {
      final Object? v = initial[i];
      if (v == Stone.black.wire) black.add(Point(i % lines, i ~/ lines));
      if (v == Stone.white.wire) white.add(Point(i % lines, i ~/ lines));
    }
  }

  GameState state = black.isEmpty && white.isEmpty
      ? createGame(size)
      : createProblemState(
          size: size, black: black, white: white, toPlay: Stone.black);

  // 수순을 그대로 다시 둔다 — 엔진이 판정을 재생성한다
  for (int i = 0; i < moves.length; i++) {
    final Object? m = moves[i];
    if (m is! Map) return const SnapshotFail('snapshotCorrupt');

    if (m['pass'] == true) {
      final PlayResult r = passMove(state);
      if (r is! PlayOk) {
        return SnapshotFail('snapshotReplayFailed', detail: '${i + 1}');
      }
      state = r.state;
      continue;
    }

    final Object? x = m['x'];
    final Object? y = m['y'];
    if (x is! int || y is! int || !inBounds(lines, x, y)) {
      return SnapshotFail('snapshotReplayFailed', detail: '${i + 1}');
    }
    final PlayResult r = tryPlay(state, x, y);
    if (r is! PlayOk) {
      return SnapshotFail('snapshotReplayFailed', detail: '${i + 1}');
    }
    state = r.state;
  }

  final Object? resigned = raw['resignedBy'];
  if (resigned is int && resigned != 0) {
    state = resign(state, Stone.fromWire(resigned));
  }

  return SnapshotOk(state);
}
