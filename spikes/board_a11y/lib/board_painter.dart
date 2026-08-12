// spikes/board_a11y/lib/board_painter.dart — 판 전체를 CustomPainter 하나로
//
// 361개 위젯이 아니라 한 번의 paint() 다. 시맨틱스 노드도 0개라
// 스크린리더 객체 탐색이 늪이 되지 않는다.

import 'package:flutter/material.dart';

import 'coord.dart';

class BoardModel {
  const BoardModel({
    required this.size,
    required this.stones,
    required this.cursor,
    required this.armed,
    this.lastMove,
  });

  final int size;

  /// 0 빈 점, 1 흑, 2 백
  final List<int> stones;
  final ({int x, int y}) cursor;
  final bool armed;
  final ({int x, int y})? lastMove;

  int at(int x, int y) => stones[y * size + x];
}

class BoardTheme {
  const BoardTheme({
    required this.background,
    required this.gridBackground,
    required this.line,
    required this.coord,
    required this.black,
    required this.white,
    required this.cursorColor,
    required this.lastMoveColor,
  });

  static const BoardTheme highContrast = BoardTheme(
    background: Color(0xFF000000),
    gridBackground: Color(0xFF111111),
    line: Color(0xFFF5F5F7),
    coord: Color(0xFFF5F5F7),
    black: Color(0xFF121212),
    white: Color(0xFFF5F5F7),
    cursorColor: Color(0xFFFFFF00),
    lastMoveColor: Color(0xFFFFD479),
  );

  final Color background;
  final Color gridBackground;
  final Color line;
  final Color coord;
  final Color black;
  final Color white;
  final Color cursorColor;
  final Color lastMoveColor;
}

const double _cellUnits = 48;
const double _edgeUnits = 24;
const double _gutterUnits = 40;

class BoardPainter extends CustomPainter {
  BoardPainter({required this.model, required this.theme, required this.showCoords});

  final BoardModel model;
  final BoardTheme theme;
  final bool showCoords;

  double get _pad => (showCoords ? _gutterUnits : 0) + _edgeUnits;
  double get _span => _cellUnits * (model.size - 1);
  double get _extent => _pad * 2 + _span;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _extent;
    canvas.save();
    canvas.translate(
      (size.width - _extent * scale) / 2,
      (size.height - _extent * scale) / 2,
    );
    canvas.scale(scale);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, _extent, _extent),
      Paint()..color = theme.background,
    );
    canvas.drawRect(
      Rect.fromLTWH(_pad - _cellUnits / 2, _pad - _cellUnits / 2,
          _span + _cellUnits, _span + _cellUnits),
      Paint()..color = theme.gridBackground,
    );

    final Paint linePaint = Paint()
      ..color = theme.line
      ..strokeWidth = 2.5;
    for (int i = 0; i < model.size; i++) {
      final double p = _pad + i * _cellUnits;
      canvas.drawLine(Offset(_pad, p), Offset(_pad + _span, p), linePaint);
      canvas.drawLine(Offset(p, _pad), Offset(p, _pad + _span), linePaint);
    }

    if (showCoords) _paintCoords(canvas);
    _paintStars(canvas);
    _paintStones(canvas);
    _paintCursor(canvas);

    canvas.restore();
  }

  void _paintCoords(Canvas canvas) {
    for (int i = 0; i < model.size; i++) {
      final double p = _pad + i * _cellUnits;
      _text(canvas, columnLabel(i), Offset(p, _pad - _gutterUnits * 0.5));
      _text(canvas, columnLabel(i), Offset(p, _pad + _span + _gutterUnits * 0.5));
      final String row = '${rowLabel(i, model.size)}';
      _text(canvas, row, Offset(_pad - _gutterUnits * 0.5, p));
      _text(canvas, row, Offset(_pad + _span + _gutterUnits * 0.5, p));
    }
  }

  void _text(Canvas canvas, String s, Offset center, {Color? color, double? size}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color ?? theme.coord,
          fontSize: size ?? _cellUnits * 0.34,
          fontFamily: 'Consolas',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintStars(Canvas canvas) {
    final List<int> coords = model.size == 19
        ? <int>[3, 9, 15]
        : model.size == 13
            ? <int>[3, 6, 9]
            : <int>[2, 4, 6];
    for (final int sy in coords) {
      for (final int sx in coords) {
        canvas.drawCircle(
          Offset(_pad + sx * _cellUnits, _pad + sy * _cellUnits),
          _cellUnits * 0.18,
          Paint()..color = theme.line,
        );
      }
    }
  }

  void _paintStones(Canvas canvas) {
    final double r = _cellUnits * 0.42;
    for (int y = 0; y < model.size; y++) {
      for (int x = 0; x < model.size; x++) {
        final int s = model.at(x, y);
        if (s == 0) continue;
        final Offset c = Offset(_pad + x * _cellUnits, _pad + y * _cellUnits);
        final Color fill = s == 1 ? theme.black : theme.white;
        canvas.drawCircle(c, r, Paint()..color = fill);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = s == 1 ? theme.white : theme.black,
        );
        // 색만으로 구분하지 않는다
        _text(canvas, s == 1 ? '흑' : '백', c,
            color: s == 1 ? theme.white : theme.black, size: _cellUnits * 0.26);
        if (model.lastMove?.x == x && model.lastMove?.y == y) {
          canvas.drawCircle(
            c,
            r * 1.15,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = theme.lastMoveColor,
          );
        }
      }
    }
  }

  void _paintCursor(Canvas canvas) {
    final Offset c =
        Offset(_pad + model.cursor.x * _cellUnits, _pad + model.cursor.y * _cellUnits);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = model.armed ? 6 : 4
      ..color = theme.cursorColor;
    // 십자선 — 확대경 사용자가 위치를 추적할 수 있게
    canvas.drawLine(Offset(_pad, c.dy), Offset(_pad + _span, c.dy),
        Paint()..color = theme.cursorColor.withValues(alpha: 0.35)..strokeWidth = 2);
    canvas.drawLine(Offset(c.dx, _pad), Offset(c.dx, _pad + _span),
        Paint()..color = theme.cursorColor.withValues(alpha: 0.35)..strokeWidth = 2);
    canvas.drawCircle(c, _cellUnits * (model.armed ? 0.52 : 0.46), p);
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.model != model || old.theme != theme || old.showCoords != showCoords;
}
