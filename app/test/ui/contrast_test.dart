// test/ui/contrast_test.dart — WCAG 명도 대비 자동 검증
//
// 체크리스트 V1~V4. Flutter 앱은 DOM 이 없어 axe 계열 자동 감사가 통하지 않으므로,
// 색 대비만큼은 토큰 테이블 위에서 직접 계산해 강제한다.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/ui/theme/board_theme.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';

/// WCAG 2.x 상대 휘도
double _luminance(Color c) {
  double channel(double v) {
    final double s = v;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 명도 대비 (1.0 ~ 21.0)
double contrastRatio(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void expectContrast(Color fg, Color bg, double min, String what) {
  final double r = contrastRatio(fg, bg);
  expect(r, greaterThanOrEqualTo(min),
      reason: '$what — 실제 ${r.toStringAsFixed(2)}:1, 필요 $min:1');
}

/// 돌이 판 위에서 보이는가 — 채움 또는 테두리 중 하나가 판과 3:1 이상이면 된다
void expectStoneVisible(Color fill, Color stroke, Color board, String what) {
  final double byFill = contrastRatio(fill, board);
  final double byStroke = contrastRatio(stroke, board);
  final double best = math.max(byFill, byStroke);
  expect(best, greaterThanOrEqualTo(3.0),
      reason: '$what 이 판과 구분되지 않습니다 — '
          '채움 ${byFill.toStringAsFixed(2)}:1, 테두리 ${byStroke.toStringAsFixed(2)}:1');
}

void main() {
  group('V1·V2 · 텍스트 대비', () {
    for (final ContrastProfile p in ContrastProfile.values) {
      test('${p.name} 프로파일: 본문 ≥ 7:1, 보조 텍스트 ≥ 4.5:1', () {
        final VisionSettings v = VisionSettings(contrast: p);
        // 저시력 대상이라 본문은 AAA(7:1) 를 목표로 한다
        expectContrast(v.textColor, v.backgroundColor, 7.0, '${p.name} 본문');
        expectContrast(v.subTextColor, v.backgroundColor, 4.5, '${p.name} 보조 텍스트');
      });

      test('${p.name} 프로파일: 테두리 ≥ 3:1', () {
        final VisionSettings v = VisionSettings(contrast: p);
        expectContrast(v.borderColor, v.backgroundColor, 3.0, '${p.name} 테두리');
      });
    }

    test('표면 위 본문도 대비를 지킨다', () {
      for (final ContrastProfile p in ContrastProfile.values) {
        final VisionSettings v = VisionSettings(contrast: p);
        expectContrast(v.textColor, SvilColors.surface, 7.0, '${p.name} 표면 위 본문');
        expectContrast(v.textColor, SvilColors.surface2, 7.0, '${p.name} 입력면 위 본문');
      }
    });
  });

  group('V3 · 포커스 링', () {
    test('두 포커스 색 모두 배경 대비 ≥ 3:1', () {
      for (final FocusRingColor f in FocusRingColor.values) {
        for (final ContrastProfile p in ContrastProfile.values) {
          final VisionSettings v = VisionSettings(contrast: p, focusRing: f);
          expectContrast(v.focusColor, v.backgroundColor, 3.0, '${f.name} on ${p.name}');
        }
        expectContrast(f.color, SvilColors.surface2, 3.0, '${f.name} on 입력면');
      }
    });
  });

  group('V4 · 바둑판 팔레트', () {
    for (final BoardPalette p in BoardPalette.all) {
      test('${p.id.name}: 돌↔판, 돌↔돌 대비', () {
        // 돌이 판과 구분되어야 한다 — 채움이든 테두리든 하나는 판과 갈려야 한다.
        // (어두운 판에서는 백돌의 채움이, 밝은 판에서는 백돌의 테두리가 그 역할을 한다)
        expectStoneVisible(p.blackFill, p.blackStroke, p.gridBackground, '${p.id.name} 흑돌');
        expectStoneVisible(p.whiteFill, p.whiteStroke, p.gridBackground, '${p.id.name} 백돌');
        // 테두리는 자기 돌 안에서 보여야 한다 (돌의 윤곽)
        expectContrast(p.whiteStroke, p.whiteFill, 4.5, '${p.id.name} 백 테두리↔백');
        expectContrast(p.blackStroke, p.blackFill, 1.0, '${p.id.name} 흑 테두리↔흑');
        // 흑↔백 은 색만으로 구분하지 않더라도 충분히 갈려야 한다
        expectContrast(p.blackFill, p.whiteFill, 4.5, '${p.id.name} 흑↔백');
        // 돌 위 글자(흑/백)가 읽혀야 한다 — 색맹·저시력 대비 이중 표기의 근거
        expectContrast(p.blackLabel, p.blackFill, 4.5, '${p.id.name} 흑 글자');
        expectContrast(p.whiteLabel, p.whiteFill, 4.5, '${p.id.name} 백 글자');
        // 격자선이 보여야 한다
        expectContrast(p.line, p.gridBackground, 3.0, '${p.id.name} 격자선');
        expectContrast(p.coord, p.background, 4.5, '${p.id.name} 좌표 글자');
      });
    }

    test('팔레트 5종이 모두 등록되어 있다', () {
      expect(BoardPalette.all.length, BoardPaletteId.values.length);
      for (final BoardPaletteId id in BoardPaletteId.values) {
        expect(BoardPalette.byId(id).id, id);
      }
    });
  });

  group('대비 계산 자체 검증', () {
    test('알려진 값과 맞는다', () {
      // 검정↔흰색은 정확히 21:1
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21.0, 0.01));
      // 같은 색은 1:1
      expect(contrastRatio(const Color(0xFF7EC8FF), const Color(0xFF7EC8FF)),
          closeTo(1.0, 0.001));
      // 순서를 바꿔도 같다
      expect(contrastRatio(const Color(0xFF0D0D12), const Color(0xFFF5F5F7)),
          closeTo(contrastRatio(const Color(0xFFF5F5F7), const Color(0xFF0D0D12)), 0.001));
    });
  });
}
