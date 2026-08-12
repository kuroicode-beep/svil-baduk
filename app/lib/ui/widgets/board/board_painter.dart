// lib/ui/widgets/board/board_painter.dart — 판 전체를 한 번의 paint() 로
//
// 361개 위젯을 만들지 않는다. 시맨틱스 노드도 여기엔 0개다 —
// Flutter 에는 격자 역할이 없어서 셀마다 노드를 만들어도 위치를 전달하지 못하고,
// MSAA 객체 탐색만 늪이 된다. 접근성은 BoardView 의 단일 노드가 담당한다.

import 'package:flutter/material.dart';

import '../../../domain/engine/board.dart';
import '../../../domain/engine/types.dart';
import '../../theme/board_theme.dart';

/// viewBox 내부 단위. 화면 크기와 무관하게 고정이라
/// 마커·글자가 판 크기 설정에 따라 상대적으로 작아지는 일이 없다.
const double kCellUnits = 48;
const double kEdgeUnits = 24;
const double kGutterUnits = 40;

/// 이보다 한 칸이 작아지면 좌표 글자가 읽히지 않는다
const double kMinCoordCellPx = 22;

class BoardRenderModel {
  const BoardRenderModel({
    required this.state,
    required this.cursor,
    required this.armed,
    required this.showCursor,
    required this.lastMove,
    required this.showCoords,
    required this.lineWidth,
  });

  final GameState state;
  final Point cursor;
  final bool armed;

  /// 키보드·확정 커서를 그릴지 (관전·종국 때는 감춘다)
  final bool showCursor;
  final Point? lastMove;
  final bool showCoords;
  final double lineWidth;

  @override
  bool operator ==(Object other) =>
      other is BoardRenderModel &&
      identical(other.state, state) &&
      other.cursor == cursor &&
      other.armed == armed &&
      other.showCursor == showCursor &&
      other.lastMove == lastMove &&
      other.showCoords == showCoords &&
      other.lineWidth == lineWidth;

  @override
  int get hashCode => Object.hash(
      state, cursor, armed, showCursor, lastMove, showCoords, lineWidth);
}

class BoardPainter extends CustomPainter {
  BoardPainter({required this.model, required this.palette});

  final BoardRenderModel model;
  final BoardPalette palette;

  int get _lines => model.state.lines;
  double get _pad => (model.showCoords ? kGutterUnits : 0) + kEdgeUnits;
  double get _span => kCellUnits * (_lines - 1);
  double get _extent => _pad * 2 + _span;

  Offset _at(int x, int y) =>
      Offset(_pad + x * kCellUnits, _pad + y * kCellUnits);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _extent;
    canvas.save();
    canvas.translate(
      (size.width - _extent * scale) / 2,
      (size.height - _extent * scale) / 2,
    );
    canvas.scale(scale);

    canvas.drawRect(Rect.fromLTWH(0, 0, _extent, _extent),
        Paint()..color = palette.background);
    canvas.drawRect(
      Rect.fromLTWH(_pad - kCellUnits / 2, _pad - kCellUnits / 2,
          _span + kCellUnits, _span + kCellUnits),
      Paint()..color = palette.gridBackground,
    );

    final Paint linePaint = Paint()
      ..color = palette.line
      ..strokeWidth = model.lineWidth;
    for (int i = 0; i < _lines; i++) {
      final double p = _pad + i * kCellUnits;
      canvas.drawLine(Offset(_pad, p), Offset(_pad + _span, p), linePaint);
      canvas.drawLine(Offset(p, _pad), Offset(p, _pad + _span), linePaint);
    }

    if (model.showCoords) _paintCoords(canvas);
    _paintStars(canvas);
    _paintStones(canvas);
    if (model.showCursor) _paintCursor(canvas);

    canvas.restore();
  }

  void _paintCoords(Canvas canvas) {
    for (int i = 0; i < _lines; i++) {
      final double p = _pad + i * kCellUnits;
      final String col = pointLabel(i, 0, _lines).substring(0, 1);
      final String row = '${_lines - i}';
      _text(canvas, col, Offset(p, _pad - kGutterUnits * 0.5), palette.coord);
      _text(canvas, col, Offset(p, _pad + _span + kGutterUnits * 0.5), palette.coord);
      _text(canvas, row, Offset(_pad - kGutterUnits * 0.5, p), palette.coord);
      _text(canvas, row, Offset(_pad + _span + kGutterUnits * 0.5, p), palette.coord);
    }
  }

  void _text(Canvas canvas, String s, Offset center, Color color,
      {double? size}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size ?? kCellUnits * 0.34,
          fontFamily: 'Consolas',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintStars(Canvas canvas) {
    for (final Point p in starPoints(model.state.size)) {
      canvas.drawCircle(_at(p.x, p.y), kCellUnits * 0.18,
          Paint()..color = palette.line);
    }
  }

  void _paintStones(Canvas canvas) {
    final double r = kCellUnits * 0.42;
    for (int y = 0; y < _lines; y++) {
      for (int x = 0; x < _lines; x++) {
        final Stone s = model.state.stoneAt(x, y);
        if (s == Stone.empty) continue;
        final Offset c = _at(x, y);
        final bool isBlack = s == Stone.black;
        canvas.drawCircle(
            c, r, Paint()..color = isBlack ? palette.blackFill : palette.whiteFill);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = isBlack ? palette.blackStroke : palette.whiteStroke,
        );
        // 색만으로 구분하지 않는다 — 돌 위에 글자를 함께 그린다
        _text(canvas, isBlack ? '흑' : '백', c,
            isBlack ? palette.blackLabel : palette.whiteLabel,
            size: kCellUnits * 0.26);

        if (model.lastMove?.x == x && model.lastMove?.y == y) {
          canvas.drawCircle(
            c,
            r * 1.18,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = palette.lastMove,
          );
        }
      }
    }
  }

  void _paintCursor(Canvas canvas) {
    final Offset c = _at(model.cursor.x, model.cursor.y);
    final Color color = palette.lastMove;
    // 십자선 — 확대경 사용자가 커서를 추적할 수 있게
    final Paint thin = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(_pad, c.dy), Offset(_pad + _span, c.dy), thin);
    canvas.drawLine(Offset(c.dx, _pad), Offset(c.dx, _pad + _span), thin);
    canvas.drawCircle(
      c,
      kCellUnits * (model.armed ? 0.52 : 0.46),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = model.armed ? 6 : 4
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.model != model || old.palette != palette;
}
