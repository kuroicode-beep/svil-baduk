// lib/ui/theme/board_theme.dart — 바둑판 팔레트
//
// 돌은 색만으로 구분하지 않는다. 판 위에 흑/백 글자를 함께 그린다.
// 각 팔레트는 돌↔판, 돌↔돌 대비가 4.5:1 이상이어야 한다 (contrast_test 가 강제).

import 'package:flutter/material.dart';

import 'svil_theme.dart';

enum BoardPaletteId {
  classic('기본'),
  maxContrast('최대 대비'),
  amberBlue('호박·파랑'),
  warmGray('따뜻한 회색'),
  inverted('반전');

  const BoardPaletteId(this.label);
  final String label;
}

class BoardPalette {
  const BoardPalette({
    required this.id,
    required this.background,
    required this.gridBackground,
    required this.line,
    required this.coord,
    required this.blackFill,
    required this.blackStroke,
    required this.blackLabel,
    required this.whiteFill,
    required this.whiteStroke,
    required this.whiteLabel,
    required this.lastMove,
    required this.hint,
  });

  final BoardPaletteId id;
  final Color background;
  final Color gridBackground;
  final Color line;
  final Color coord;
  final Color blackFill;
  final Color blackStroke;
  final Color blackLabel;
  final Color whiteFill;
  final Color whiteStroke;
  final Color whiteLabel;
  final Color lastMove;
  final Color hint;

  static const BoardPalette classic = BoardPalette(
    id: BoardPaletteId.classic,
    background: SvilColors.bg,
    gridBackground: SvilColors.surface,
    line: Color(0xFFC9C9D4),
    coord: Color(0xFFC9C9D4),
    blackFill: Color(0xFF121212),
    blackStroke: Color(0xFFF5F5F7),
    blackLabel: Color(0xFFF5F5F7),
    whiteFill: Color(0xFFF5F5F7),
    whiteStroke: Color(0xFF121212),
    whiteLabel: Color(0xFF121212),
    lastMove: SvilColors.warning,
    hint: SvilColors.positive,
  );

  static const BoardPalette maxContrast = BoardPalette(
    id: BoardPaletteId.maxContrast,
    background: Color(0xFF000000),
    gridBackground: Color(0xFF111111),
    line: Color(0xFFFFFFFF),
    coord: Color(0xFFFFFFFF),
    blackFill: Color(0xFF000000),
    blackStroke: Color(0xFFFFFFFF),
    blackLabel: Color(0xFFFFFFFF),
    whiteFill: Color(0xFFFFFFFF),
    whiteStroke: Color(0xFF000000),
    whiteLabel: Color(0xFF000000),
    lastMove: Color(0xFFFFFF00),
    hint: Color(0xFF00FF88),
  );

  static const BoardPalette amberBlue = BoardPalette(
    id: BoardPaletteId.amberBlue,
    background: Color(0xFF000000),
    gridBackground: Color(0xFF0E0E16),
    line: Color(0xFFB3DDFF),
    coord: Color(0xFFB3DDFF),
    blackFill: Color(0xFF0A2A45),
    blackStroke: Color(0xFFB3DDFF),
    blackLabel: Color(0xFFB3DDFF),
    whiteFill: Color(0xFFFFD479),
    whiteStroke: Color(0xFF2A1A00),
    whiteLabel: Color(0xFF2A1A00),
    lastMove: Color(0xFFFFFFFF),
    hint: Color(0xFF7EE2A8),
  );

  static const BoardPalette warmGray = BoardPalette(
    id: BoardPaletteId.warmGray,
    background: Color(0xFF14120F),
    gridBackground: Color(0xFF201C16),
    line: Color(0xFFE8E0D4),
    coord: Color(0xFFE8E0D4),
    blackFill: Color(0xFF15130F),
    blackStroke: Color(0xFFE8E0D4),
    blackLabel: Color(0xFFE8E0D4),
    whiteFill: Color(0xFFF3EDE2),
    whiteStroke: Color(0xFF15130F),
    whiteLabel: Color(0xFF15130F),
    lastMove: Color(0xFFFFB347),
    hint: Color(0xFF8FE3B0),
  );

  /// 밝은 판 — 어두운 배경이 눈부심을 유발하는 일부 저시력 사용자를 위해.
  /// 밝은 판에서는 테두리 방향이 뒤집힌다: 흑돌은 어두운 테두리,
  /// 백돌은 판과 구분되도록 반드시 어두운 테두리를 가져야 한다
  /// (흰 돌 ↔ 밝은 판은 그 자체로 1.2:1 밖에 안 된다).
  static const BoardPalette inverted = BoardPalette(
    id: BoardPaletteId.inverted,
    background: Color(0xFFF5F5F7),
    gridBackground: Color(0xFFE6E6EC),
    line: Color(0xFF16161D),
    coord: Color(0xFF16161D),
    blackFill: Color(0xFF000000),
    blackStroke: Color(0xFF000000),
    blackLabel: Color(0xFFF5F5F7),
    whiteFill: Color(0xFFFFFFFF),
    whiteStroke: Color(0xFF16161D),
    whiteLabel: Color(0xFF16161D),
    lastMove: Color(0xFFB35A00),
    hint: Color(0xFF00662E),
  );

  static const List<BoardPalette> all = <BoardPalette>[
    classic,
    maxContrast,
    amberBlue,
    warmGray,
    inverted,
  ];

  static BoardPalette byId(BoardPaletteId id) =>
      all.firstWhere((BoardPalette p) => p.id == id, orElse: () => classic);
}
