// lib/application/game_controller.dart — 대국 상태 + 낭독
//
// 하우스 관례대로 ChangeNotifier 하나. 상태관리 패키지를 쓰지 않는다.

import 'package:flutter/foundation.dart';

import '../domain/engine/board.dart';
import '../domain/engine/types.dart';
import '../domain/input/board_speech.dart';
import '../domain/input/coord_input.dart';

/// 착수 시도의 결과 — 화면이 무엇을 낭독할지 정하는 근거
sealed class PlayOutcome {
  const PlayOutcome();
}

final class PlayedMove extends PlayOutcome {
  const PlayedMove(this.speech);
  final String speech;
}

final class RejectedMove extends PlayOutcome {
  const RejectedMove(this.error, this.speech);
  final MoveError error;
  final String speech;
}

final class SpokeOnly extends PlayOutcome {
  const SpokeOnly(this.speech);
  final String speech;
}

final class GameEnded extends PlayOutcome {
  const GameEnded(this.speech);
  final String speech;
}

/// 반칙 사유를 사람이 듣는 문장으로. 침묵하거나 "잘못된 수"로 뭉뚱그리지 않는다.
typedef MoveErrorPhrase = String Function(MoveError e);

/// 입력 오류 문장
typedef CoordErrorPhrase = String Function(CoordError e, int lines);

class GameController extends ChangeNotifier {
  GameController({
    required BoardSize size,
    required this.speech,
    required this.moveErrorPhrase,
    required this.coordErrorPhrase,
    this.detail = SpeechDetail.terse,
  }) : _state = createGame(size) {
    _cursor = Point(size.lines ~/ 2, size.lines ~/ 2);
  }

  final BoardSpeech speech;
  final MoveErrorPhrase moveErrorPhrase;
  final CoordErrorPhrase coordErrorPhrase;
  SpeechDetail detail;

  GameState _state;
  late Point _cursor;
  bool _armed = false;

  GameState get state => _state;
  Point get cursor => _cursor;
  bool get armed => _armed;
  int get lines => _state.lines;

  Point? get lastMove {
    if (_state.history.isEmpty) return null;
    final Move m = _state.history.last;
    return m.isPass ? null : m.point;
  }

  /// 커서 아래 지점의 낭독 문장 — Semantics.value 로 나간다
  String get cursorSpeech => speech.point(
        _state,
        _cursor.x,
        _cursor.y,
        detail: detail,
        lastMove: lastMove,
      );

  String get cursorLabel => pointLabel(_cursor.x, _cursor.y, lines);

  bool get cursorOccupied => _state.stoneAt(_cursor.x, _cursor.y) != Stone.empty;

  /// 기하학적으로 한 칸. 합법 지점으로 점프하지 않는다 —
  /// 커서가 판을 가로질러 순간이동하면 위치 감각이 무너진다.
  void moveCursor(int dx, int dy) {
    final Point next = Point(
      (_cursor.x + dx).clamp(0, lines - 1),
      (_cursor.y + dy).clamp(0, lines - 1),
    );
    if (next == _cursor && !_armed) return;
    _cursor = next;
    _armed = false;
    notifyListeners();
  }

  void setCursor(Point p) {
    if (p.x < 0 || p.y < 0 || p.x >= lines || p.y >= lines) return;
    _cursor = p;
    _armed = false;
    notifyListeners();
  }

  void setCursorColumn(int x) => setCursor(Point(x.clamp(0, lines - 1), _cursor.y));

  void disarm() {
    if (!_armed) return;
    _armed = false;
    notifyListeners();
  }

  /// 확정 모드에서 첫 번째 입력 — 지점을 겨눈다
  void arm() {
    _armed = true;
    notifyListeners();
  }

  /// 실제 착수
  PlayOutcome place(int x, int y) {
    final PlayResult r = tryPlay(_state, x, y);
    if (r is PlayErr) {
      // 좌표를 앞에 두어 어디가 문제인지 먼저 알린다
      final String msg =
          '${pointLabel(x, y, lines)} ${moveErrorPhrase(r.error)}';
      return RejectedMove(r.error, msg);
    }
    final PlayOk ok = r as PlayOk;
    _state = ok.state;
    _cursor = Point(x, y);
    _armed = false;
    notifyListeners();
    return PlayedMove(speech.moveResult(_state, ok.move));
  }

  PlayOutcome placeAtCursor() => place(_cursor.x, _cursor.y);

  PlayOutcome pass() {
    final PlayResult r = passMove(_state);
    if (r is PlayErr) {
      return RejectedMove(r.error, moveErrorPhrase(r.error));
    }
    final PlayOk ok = r as PlayOk;
    _state = ok.state;
    _armed = false;
    notifyListeners();
    if (_state.ended) {
      return GameEnded(speech.summary(_state, lastMove: lastMove));
    }
    return PlayedMove(
      '${speech.moveResult(_state, ok.move)}',
    );
  }

  PlayOutcome resignGame(Player who) {
    _state = resign(_state, who);
    notifyListeners();
    return GameEnded(speech.summary(_state, lastMove: lastMove));
  }

  /// 상대(AI·원격)가 둔 수를 반영한다
  PlayOutcome applyOpponent(int x, int y) {
    final PlayResult r = tryPlay(_state, x, y);
    if (r is PlayErr) return RejectedMove(r.error, moveErrorPhrase(r.error));
    final PlayOk ok = r as PlayOk;
    _state = ok.state;
    notifyListeners();
    return PlayedMove(speech.moveResult(_state, ok.move));
  }

  /// 좌표 입력 한 줄을 처리한다 — 착수·명령·질의를 모두 받는다
  PlayOutcome submitInput(String raw, {String? lastSpoken}) {
    final CoordInput parsed = parseCoordInput(raw, _state.size);
    switch (parsed) {
      case CoordPoint(:final int x, :final int y):
        setCursor(Point(x, y));
        return place(x, y);

      case CoordQuery(x: final int? qx, y: final int? qy, row: final int? row):
        if (qx != null && qy != null) {
          return SpokeOnly(
            speech.point(_state, qx, qy, detail: SpeechDetail.full, lastMove: lastMove),
          );
        }
        return SpokeOnly(speech.row(_state, row!));

      case CoordCommand(:final BoardCommand command):
        return _runCommand(command, lastSpoken);

      case CoordError():
        return SpokeOnly(coordErrorPhrase(parsed, lines));
    }
  }

  PlayOutcome _runCommand(BoardCommand c, String? lastSpoken) => switch (c) {
        BoardCommand.summary =>
          SpokeOnly(speech.summary(_state, lastMove: lastMove)),
        BoardCommand.repeat => SpokeOnly(lastSpoken ?? cursorSpeech),
        BoardCommand.pass => pass(),
        BoardCommand.resign => resignGame(_state.toPlay),
        // 아래는 화면이 처리한다 (확인창·엔진 호출이 필요)
        BoardCommand.undo ||
        BoardCommand.score ||
        BoardCommand.hint ||
        BoardCommand.help =>
          const SpokeOnly(''),
      };

  /// 화면이 직접 다뤄야 하는 명령인지
  static bool needsScreen(BoardCommand c) =>
      c == BoardCommand.undo ||
      c == BoardCommand.score ||
      c == BoardCommand.hint ||
      c == BoardCommand.help;

  void reset(BoardSize size) {
    _state = createGame(size);
    _cursor = Point(size.lines ~/ 2, size.lines ~/ 2);
    _armed = false;
    notifyListeners();
  }
}
