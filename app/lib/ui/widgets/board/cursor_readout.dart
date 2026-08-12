// lib/ui/widgets/board/cursor_readout.dart — 커서 위치의 화면상 쌍둥이
//
// 모든 발화에는 화면에 보이는 짝이 있어야 한다.
// 스크린리더 안내가 유실되어도(Flutter 의 announce 는 실제로 유실된다)
// 정보가 화면에 남아 있으면 저시력 사용자는 계속 진행할 수 있다.
//
// ExcludeSemantics 인 이유: 같은 내용이 판의 Semantics.value 로 이미 나간다.
// 중복 발화는 무발화보다 나쁘다.

import 'package:flutter/material.dart';

import '../../theme/svil_theme.dart';

class CursorReadout extends StatelessWidget {
  const CursorReadout({
    required this.text,
    required this.vision,
    this.status,
    super.key,
  });

  final String text;
  final VisionSettings vision;

  /// 반칙·종국 등 짧은 상태 문구
  final String? status;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SvilColors.surface2,
          border: Border.all(color: vision.borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 화면에서 가장 큰 글자 — 가장 자주 읽는 값이다
            Text(
              text,
              style: monoStyle(
                size: vision.baseFontSize * 1.78,
                color: vision.focusColor,
              ),
            ),
            if (status != null && status!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  status!,
                  style: TextStyle(
                    fontSize: vision.baseFontSize,
                    color: vision.textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
