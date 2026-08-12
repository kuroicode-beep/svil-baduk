// lib/ui/screens/home_screen.dart — 시작 화면
//
// 항목 수를 적게 유지한다. 스크린리더로 도는 목록은 짧을수록 좋고,
// 저시력 사용자에게는 큰 글자로 몇 개만 보이는 편이 낫다.

import 'package:flutter/material.dart';

import '../../application/app_container.dart';
import '../../data/db/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../theme/svil_theme.dart';
import '../../version.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';
import 'solo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.container, super.key});

  final AppContainer container;

  Lang get _lang => container.settings.settings.lang;

  @override
  Widget build(BuildContext context) {
    final AppSettings st = container.settings.settings;

    return Scaffold(
      appBar: AppBar(
        // 버전은 늘 보인다 (하우스 규칙)
        title: Text('SVIL Baduk  v$appVersion'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: S.settings(_lang),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(container: container),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(S.tagline(_lang),
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          _tile(
            context,
            label: S.solo(_lang),
            detail: '${st.rankId} · ${_sizeLabel(st)}',
            onTap: () => _openSolo(context, st),
          ),
          _tile(
            context,
            label: S.learn(_lang),
            detail: '${container.progress.solved.length} / '
                '${container.curriculum.problemCount}',
            onTap: () => _openLearn(context, st),
          ),
        ],
      ),
    );
  }

  String _sizeLabel(AppSettings st) => '${st.boardSize.lines}${S.rowSuffix(_lang)}';

  Widget _tile(
    BuildContext context, {
    required String label,
    required String detail,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          button: true,
          label: '$label, $detail',
          child: ExcludeSemantics(
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kListItemMin),
                alignment: Alignment.centerLeft,
              ),
              onPressed: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );

  void _openSolo(BuildContext context, AppSettings st) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SoloScreen(
        settings: st,
        vision: container.vision.vision,
        size: st.boardSize,
        caps: container.caps,
      ),
    ));
  }

  void _openLearn(BuildContext context, AppSettings st) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LearnScreen(
        curriculum: container.curriculum,
        settings: st,
        vision: container.vision.vision,
        solved: container.progress.solved,
        onProgress: container.progress.save,
      ),
    ));
  }
}
