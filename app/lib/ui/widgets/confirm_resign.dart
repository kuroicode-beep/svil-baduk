// lib/ui/widgets/confirm_resign.dart — 기권 확인창 (체크리스트 A15)
//
// 기권은 항상 확인창을 거친다 — 버튼이든 좌표칸의 "기권" 명령이든.
// 되돌릴 수 없는 행동을 한 번의 탭·엔터로 끝내지 않는다.

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/svil_theme.dart';

/// true 를 돌려주면 호출자가 실제로 기권한다
Future<bool> confirmResign(BuildContext context, Lang lang) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(S.resignConfirmTitle(lang)),
      content: Text(S.resignConfirmBody(lang)),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(kTouchLarge, kTouchLarge)),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(S.cancel(lang)),
        ),
        TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(kTouchLarge, kTouchLarge)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(S.resign(lang)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
