// lib/ui/screens/settings_screen.dart — 설정
//
// 전부 라디오 목록이다. 드롭다운·슬라이더는 스크린리더에서 값 하나만
// 읽히고 선택지 전체를 훑기 어려워서 쓰지 않는다.
//
// 항목마다 왜 그 선택지가 있는지 한 줄 설명을 붙인다. "고대비" 가 무엇을
// 바꾸는지 모르면 저시력 사용자가 자기에게 맞는 값을 못 고른다.

import 'package:flutter/material.dart';

import '../../application/app_container.dart';
import '../../data/db/settings_store.dart';
import '../../domain/ai/ranks.dart';
import '../../domain/engine/types.dart';
import '../../i18n/strings.g.dart';
import '../theme/board_theme.dart';
import '../theme/svil_theme.dart';
import '../../version.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.container, super.key});

  final AppContainer container;

  AppSettings get _st => container.settings.settings;
  Lang get _lang => _st.lang;

  void _set(AppSettings next) {
    container.settings.update(next);
    // 시각 설정은 별도 컨트롤러가 들고 있으므로 함께 맞춘다
    container.vision
      ..update(next.toVision(systemReduceMotion: false))
      ..setPalette(next.palette)
      ..setVerbosity(next.verbosity);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: container.settings,
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(title: Text(S.settings(_lang))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _section(context, S.settingsVision(_lang)),
            _choices<Lang>(
              context,
              label: S.language(_lang),
              value: _st.lang,
              options: <_Choice<Lang>>[
                for (final Lang l in Lang.values)
                  _Choice<Lang>(l, langLabels[l]!),
              ],
              onChanged: (Lang v) => _set(_st.copyWith(lang: v)),
            ),
            _choices<ContrastProfile>(
              context,
              label: S.contrastProfile(_lang),
              value: _st.contrast,
              options: <_Choice<ContrastProfile>>[
                _Choice<ContrastProfile>(
                    ContrastProfile.standard, S.contrastStandard(_lang)),
                _Choice<ContrastProfile>(
                    ContrastProfile.high, S.contrastHigh(_lang)),
                _Choice<ContrastProfile>(
                    ContrastProfile.maximum, S.contrastMax(_lang)),
              ],
              onChanged: (ContrastProfile v) =>
                  _set(_st.copyWith(contrast: v)),
            ),
            _choices<FocusRingColor>(
              context,
              label: S.focusRingLabel(_lang),
              value: _st.focusRing,
              options: <_Choice<FocusRingColor>>[
                _Choice<FocusRingColor>(
                    FocusRingColor.amber, S.focusRingAmber(_lang)),
                _Choice<FocusRingColor>(
                    FocusRingColor.pureYellow, S.focusRingYellow(_lang)),
              ],
              onChanged: (FocusRingColor v) =>
                  _set(_st.copyWith(focusRing: v)),
            ),
            _choices<double>(
              context,
              label: S.fontSize(_lang),
              value: _st.fontSize,
              options: const <_Choice<double>>[
                _Choice<double>(16, '16'),
                _Choice<double>(18, '18'),
                _Choice<double>(22, '22'),
                _Choice<double>(26, '26'),
                _Choice<double>(32, '32'),
              ],
              onChanged: (double v) => _set(_st.copyWith(fontSize: v)),
            ),
            _choices<ReduceMotionSetting>(
              context,
              label: S.reduceMotionLabel(_lang),
              value: _st.reduceMotion,
              options: <_Choice<ReduceMotionSetting>>[
                _Choice<ReduceMotionSetting>(
                    ReduceMotionSetting.system, S.reduceMotionSystem(_lang)),
                _Choice<ReduceMotionSetting>(
                    ReduceMotionSetting.on, S.onLabel(_lang)),
                _Choice<ReduceMotionSetting>(
                    ReduceMotionSetting.off, S.offLabel(_lang)),
              ],
              onChanged: (ReduceMotionSetting v) =>
                  _set(_st.copyWith(reduceMotion: v)),
            ),

            _section(context, S.settingsBoard(_lang)),
            _choices<BoardSize>(
              context,
              label: S.boardSize(_lang),
              value: _st.boardSize,
              options: <_Choice<BoardSize>>[
                for (final BoardSize b in BoardSize.values)
                  _Choice<BoardSize>(b, '${b.lines}${S.rowSuffix(_lang)}'),
              ],
              onChanged: (BoardSize v) => _set(_st.copyWith(boardSize: v)),
            ),
            _choices<BoardPaletteId>(
              context,
              label: S.paletteLabel(_lang),
              value: _st.palette,
              options: <_Choice<BoardPaletteId>>[
                for (final BoardPaletteId p in BoardPaletteId.values)
                  _Choice<BoardPaletteId>(p, _paletteName(p)),
              ],
              onChanged: (BoardPaletteId v) => _set(_st.copyWith(palette: v)),
            ),
            _choices<CoordMode>(
              context,
              label: S.coordModeLabel(_lang),
              value: _st.coordMode,
              options: <_Choice<CoordMode>>[
                _Choice<CoordMode>(CoordMode.auto, S.coordAuto(_lang)),
                _Choice<CoordMode>(CoordMode.on, S.coordOn(_lang)),
                _Choice<CoordMode>(CoordMode.off, S.coordOff(_lang)),
              ],
              onChanged: (CoordMode v) => _set(_st.copyWith(coordMode: v)),
            ),

            _section(context, S.settingsGame(_lang)),
            _choices<OpponentKind>(
              context,
              label: S.opponentLabel(_lang),
              value: _st.opponent,
              options: <_Choice<OpponentKind>>[
                _Choice<OpponentKind>(
                    OpponentKind.none, S.opponentNone(_lang)),
                _Choice<OpponentKind>(
                    OpponentKind.builtin, S.opponentBuiltin(_lang)),
                // 못 쓰는 기기에서는 아예 안 보여준다 (눌러도 안 되는 것보다 낫다)
                if (container.caps.canRunKataGo)
                  _Choice<OpponentKind>(
                      OpponentKind.katago, S.opponentKataGo(_lang)),
              ],
              onChanged: (OpponentKind v) => _set(_st.copyWith(opponent: v)),
            ),
            _choices<String>(
              context,
              label: S.difficulty(_lang),
              value: _st.rankId,
              options: <_Choice<String>>[
                for (final RankOption r in kRanks)
                  _Choice<String>(r.id, '${r.level}'),
              ],
              onChanged: (String v) => _set(_st.copyWith(rankId: v)),
            ),
            _choices<PlaceMode>(
              context,
              label: S.placeModeLabel(_lang),
              value: _st.placeMode,
              options: <_Choice<PlaceMode>>[
                _Choice<PlaceMode>(
                    PlaceMode.direct, S.placeModeDirect(_lang)),
                _Choice<PlaceMode>(
                    PlaceMode.confirm, S.placeModeConfirm(_lang)),
              ],
              onChanged: (PlaceMode v) => _set(_st.copyWith(placeMode: v)),
            ),
            _choices<GoRules>(
              context,
              label: S.goRules(_lang),
              value: _st.goRules,
              options: <_Choice<GoRules>>[
                _Choice<GoRules>(
                    GoRules.japanese, S.goRulesJapanese(_lang)),
                _Choice<GoRules>(GoRules.chinese, S.goRulesChinese(_lang)),
              ],
              onChanged: (GoRules v) => _set(_st.copyWith(goRules: v)),
            ),
            // 계가는 사석을 못 가린다 — 화면에서 분명히 말해 둔다
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(S.scoreDeadStonesNote(_lang),
                  style: Theme.of(context).textTheme.bodySmall),
            ),

            _section(context, S.settingsSpeech(_lang)),
            _choices<AnnounceVerbosity>(
              context,
              label: S.verbosityLabel(_lang),
              value: _st.verbosity,
              options: <_Choice<AnnounceVerbosity>>[
                _Choice<AnnounceVerbosity>(
                    AnnounceVerbosity.terse, S.verbosityTerse(_lang)),
                _Choice<AnnounceVerbosity>(
                    AnnounceVerbosity.full, S.verbosityFull(_lang)),
              ],
              onChanged: (AnnounceVerbosity v) =>
                  _set(_st.copyWith(verbosity: v)),
            ),

            const SizedBox(height: 24),
            Text('v$appVersion', style: monoStyle(size: 16)),
          ],
        ),
      ),
    );
  }

  String _paletteName(BoardPaletteId p) => switch (p) {
        BoardPaletteId.classic => S.paletteClassic(_lang),
        BoardPaletteId.maxContrast => S.paletteMaxContrast(_lang),
        BoardPaletteId.amberBlue => S.paletteAmberBlue(_lang),
        BoardPaletteId.warmGray => S.paletteWarmGray(_lang),
        BoardPaletteId.inverted => S.paletteInverted(_lang),
      };

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _choices<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<_Choice<T>> options,
    required void Function(T) onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            for (final _Choice<T> o in options)
              // RadioListTile 은 선택 상태를 스크린리더에 그대로 전달한다
              RadioListTile<T>(
                title: Text(o.label),
                value: o.value,
                // ignore: deprecated_member_use
                groupValue: value,
                // ignore: deprecated_member_use
                onChanged: (T? v) {
                  if (v != null) onChanged(v);
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.comfortable,
              ),
          ],
        ),
      );
}

class _Choice<T> {
  const _Choice(this.value, this.label);
  final T value;
  final String label;
}
