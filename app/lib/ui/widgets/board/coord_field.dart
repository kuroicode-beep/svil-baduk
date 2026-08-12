// lib/ui/widgets/board/coord_field.dart — 좌표·명령어 입력
//
// 이건 보조 수단이 아니다. Flutter 에서 격자를 스크린리더에 노출할 수 없으므로
// 좌표를 말로 입력하는 것이 **동등한 1급 경로**다. 항상 화면에 보인다.

import 'package:flutter/material.dart';

import '../../theme/svil_theme.dart';

class CoordField extends StatefulWidget {
  const CoordField({
    required this.label,
    required this.hint,
    required this.helper,
    required this.vision,
    required this.onSubmit,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String hint;
  final String helper;
  final VisionSettings vision;

  /// 성공하면 true 를 돌려준다 — 그때만 입력을 비운다
  final bool Function(String raw) onSubmit;
  final bool enabled;

  @override
  State<CoordField> createState() => CoordFieldState();
}

class CoordFieldState extends State<CoordField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'coord');

  void requestFocus() => _focus.requestFocus();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final bool ok = widget.onSubmit(raw);
    if (ok) {
      _ctrl.clear();
    } else {
      // 실패하면 지우지 않고 전체 선택 — 고쳐 쓰기 쉽게
      _ctrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    }
    // 어느 쪽이든 포커스는 여기 남는다
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      enabled: widget.enabled,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.go,
      style: monoStyle(
        size: widget.vision.baseFontSize * 1.33,
        color: widget.vision.textColor,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        helperMaxLines: 3,
        // 터치 최소 크기를 지킨다
        constraints: const BoxConstraints(minHeight: kTouchLarge),
      ),
      onSubmitted: _submit,
    );
  }
}
