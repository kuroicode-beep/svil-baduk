// lib/ui/widgets/board/board_view.dart — 판의 접근성·입력 레이어
//
// 핵심 구조: 판 안에 포커스 노드는 **정확히 하나**다.
// Flutter 에는 grid/gridcell 역할이 없고 aria-activedescendant 도 없으며
// Windows 는 MSAA 라 행·열 좌표를 전달할 통로가 없다. 그래서 판을
// "탐색하는 공간"이 아니라 **값을 가진 컨트롤 하나**로 만든다.
// 커서 위치는 Semantics.value 로 나가고(MSAA VALUECHANGE), 사건·오류만
// sendAnnouncement 로 나간다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/engine/types.dart';
import '../../theme/board_theme.dart';
import '../../theme/svil_theme.dart';
import 'board_painter.dart';

/// 판이 화면에 요청하는 동작 — 화면이 확인창·엔진 호출을 담당한다
enum BoardIntent { place, arm, disarm, help }

class BoardView extends StatefulWidget {
  const BoardView({
    required this.state,
    required this.cursor,
    required this.armed,
    required this.lastMove,
    required this.palette,
    required this.vision,
    required this.semanticsLabel,
    required this.semanticsValue,
    required this.semanticsHint,
    required this.interactive,
    required this.onMoveCursor,
    required this.onSetCursor,
    required this.onIntent,
    this.ownership,
    this.coordMode = CoordDisplayMode.auto,
    this.lineWidth = 2.5,
    super.key,
  });

  final GameState state;
  final Point cursor;
  final bool armed;
  final Point? lastMove;
  final BoardPalette palette;
  final VisionSettings vision;

  /// 거의 바뀌지 않는 이름 — "19 줄 바둑판"
  final String semanticsLabel;

  /// 살아 있는 채널 — 커서 위치가 여기로 나간다
  final String semanticsValue;
  final String semanticsHint;
  final bool interactive;

  final void Function(int dx, int dy) onMoveCursor;
  final void Function(Point p) onSetCursor;
  final void Function(BoardIntent intent) onIntent;

  /// 계가 결과의 집 소유. null 이면 표시하지 않는다.
  final List<Stone>? ownership;
  final CoordDisplayMode coordMode;
  final double lineWidth;

  @override
  State<BoardView> createState() => BoardViewState();
}

enum CoordDisplayMode { auto, on, off }

class BoardViewState extends State<BoardView> {
  final FocusNode _focus = FocusNode(debugLabel: 'board');
  double _cellPx = 0;

  /// 화면(솔로 등)이 좌표 입력에서 판으로 포커스를 되돌릴 때 쓴다
  void requestFocus() => _focus.requestFocus();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool get _showCoords => switch (widget.coordMode) {
        CoordDisplayMode.on => true,
        CoordDisplayMode.off => false,
        // 아직 측정 전이면 표시 — 깜빡임보다 낫다
        CoordDisplayMode.auto => _cellPx == 0 || _cellPx >= kMinCoordCellPx,
      };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.interactive) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey k = event.logicalKey;

    KeyEventResult move(int dx, int dy) {
      widget.onMoveCursor(dx, dy);
      return KeyEventResult.handled;
    }

    switch (k) {
      case LogicalKeyboardKey.arrowRight:
        return move(1, 0);
      case LogicalKeyboardKey.arrowLeft:
        return move(-1, 0);
      case LogicalKeyboardKey.arrowDown:
        return move(0, 1);
      case LogicalKeyboardKey.arrowUp:
        return move(0, -1);
      case LogicalKeyboardKey.pageUp:
        return move(0, -5);
      case LogicalKeyboardKey.pageDown:
        return move(0, 5);
      case LogicalKeyboardKey.home:
        widget.onSetCursor(Point(0, widget.cursor.y));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        widget.onSetCursor(Point(widget.state.lines - 1, widget.cursor.y));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (!widget.armed) return KeyEventResult.ignored; // 포커스를 가두지 않는다
        widget.onIntent(BoardIntent.disarm);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        widget.onIntent(widget.armed ? BoardIntent.place : BoardIntent.arm);
        return KeyEventResult.handled;
    }
    // ? 는 판 요약
    if (event.character == '?') {
      widget.onIntent(BoardIntent.help);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 화면 좌표 → 교차점. 그리기와 같은 식을 써야 오터치가 없다.
  Point? _hitTest(Offset local, Size size) {
    final int lines = widget.state.lines;
    final double pad = (_showCoords ? kGutterUnits : 0) + kEdgeUnits;
    final double span = kCellUnits * (lines - 1);
    final double extent = pad * 2 + span;
    final double scale = size.shortestSide / extent;
    final double ox = (size.width - extent * scale) / 2;
    final double oy = (size.height - extent * scale) / 2;

    final double ux = (local.dx - ox) / scale;
    final double uy = (local.dy - oy) / scale;
    final int x = ((ux - pad) / kCellUnits).round();
    final int y = ((uy - pad) / kCellUnits).round();
    if (x < 0 || y < 0 || x >= lines || y >= lines) return null;
    return Point(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double side = c.biggest.shortestSide;
        final double cell = side / (widget.state.lines + 1);
        if ((cell - _cellPx).abs() > 0.5) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _cellPx = cell);
          });
        }

        final BoardRenderModel model = BoardRenderModel(
          state: widget.state,
          cursor: widget.cursor,
          armed: widget.armed,
          showCursor: widget.interactive,
          lastMove: widget.lastMove,
          showCoords: _showCoords,
          lineWidth: widget.lineWidth,
              ownership: widget.ownership,
        );

        return Semantics(
          // 판 전체에서 포커스를 받는 유일한 노드
          focusable: true,
          focused: _focus.hasFocus,
          label: widget.semanticsLabel,
          value: widget.semanticsValue,
          hint: widget.semanticsHint,
          onTap: widget.interactive
              ? () => widget.onIntent(BoardIntent.place)
              : null,
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _onKey,
            onFocusChange: (_) => setState(() {}),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) {
                _focus.requestFocus();
                if (!widget.interactive) return;
                final Point? p = _hitTest(d.localPosition, c.biggest);
                if (p == null) return;
                widget.onSetCursor(p);
                // 확정 모드는 화면이 판단한다 — 여기서는 의도만 올린다
                widget.onIntent(BoardIntent.place);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focus.hasFocus
                        ? widget.vision.focusColor
                        : widget.vision.borderColor,
                    width: _focus.hasFocus ? 3 : 2,
                  ),
                ),
                child: CustomPaint(
                  painter: BoardPainter(model: model, palette: widget.palette),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
