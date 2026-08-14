// lib/ui/screens/solo_setup_screen.dart — 대국 설정 (Stitch solo_setup 복원)
//
// "AI와 겨루기" 를 누르면 바로 판이 아니라 여기로 온다 — 판 크기·상대·
// 난이도를 고르고 시작한다. 고른 값은 설정에 저장돼 다음에도 유지된다.
// 전부 라디오 목록: 드롭다운은 스크린리더에서 선택지 전체를 훑기 어렵다.

import 'package:flutter/material.dart';

import '../../application/app_container.dart';
import '../../data/db/settings_store.dart';
import '../../domain/ai/ranks.dart';
import '../../domain/engine/types.dart';
import '../../i18n/strings.g.dart';
import '../theme/svil_theme.dart';
import 'solo_screen.dart';

class SoloSetupScreen extends StatelessWidget {
  const SoloSetupScreen({required this.container, super.key});

  final AppContainer container;

  AppSettings get _st => container.settings.settings;
  Lang get _lang => _st.lang;

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => SoloScreen(
        settings: container.settings.settings,
        vision: container.vision.vision,
        size: container.settings.settings.boardSize,
        caps: container.caps,
        profileCtrl: container.profile,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: container.settings,
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(title: Text(S.setupTitle(_lang))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _group<BoardSize>(
              context,
              label: S.boardSize(_lang),
              value: _st.boardSize,
              options: <(BoardSize, String)>[
                for (final BoardSize b in BoardSize.values)
                  (b, '${b.lines}${S.rowSuffix(_lang)}'),
              ],
              onChanged: (BoardSize v) =>
                  container.settings.update(_st.copyWith(boardSize: v)),
            ),
            _group<OpponentKind>(
              context,
              label: S.opponentLabel(_lang),
              value: _st.opponent,
              options: <(OpponentKind, String)>[
                (OpponentKind.none, S.opponentNone(_lang)),
                (OpponentKind.builtin, S.opponentBuiltin(_lang)),
                if (container.caps.canRunKataGo)
                  (OpponentKind.katago, S.opponentKataGo(_lang)),
              ],
              onChanged: (OpponentKind v) =>
                  container.settings.update(_st.copyWith(opponent: v)),
            ),
            _group<String>(
              context,
              label: S.difficulty(_lang),
              value: _st.rankId,
              options: <(String, String)>[
                for (final RankOption r in kRanks) (r.id, '${r.level}'),
              ],
              onChanged: (String v) =>
                  container.settings.update(_st.copyWith(rankId: v)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(kListItemMin)),
              onPressed: () => _start(context),
              child: Text(S.startGame(_lang)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<(T, String)> options,
    required void Function(T) onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            for (final (T, String) o in options)
              RadioListTile<T>(
                title: Text(o.$2),
                value: o.$1,
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
