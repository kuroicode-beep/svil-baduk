// lib/ui/screens/home_screen.dart — 시작 화면 (Stitch 기획 복원, 2026-08-14)
//
// 구조는 docs/design/stitch/home_svil_baduk 을 따른다:
// 프로필 카드(별명·급수·레벨·전적·경험치) + 메뉴 5개 + 도움말.
//
// 타일은 어두운 바탕 + 밝은 글자다. 밝은 채움 버튼 위에 회색 보조 텍스트를
// 얹었다가 대비가 무너진 적이 있다(0.16.1 스크린샷) — 저시력 앱에서 타일은
// 표면색 위에 본문색이 원칙이다.

import 'package:flutter/material.dart';

import '../../application/app_container.dart';
import '../../data/db/settings_store.dart';
import '../../domain/profile/profile.dart';
import '../../i18n/strings.g.dart';
import '../theme/svil_theme.dart';
import '../../version.dart';
import 'character_screen.dart';
import 'learn_screen.dart';
import 'multi_screen.dart';
import 'settings_screen.dart';
import 'solo_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.container, super.key});

  final AppContainer container;

  Lang get _lang => container.settings.settings.lang;

  @override
  Widget build(BuildContext context) {
    // 다른 화면에서 돌아왔을 때 타일의 진행·전적·설정 요약이 낡아 있으면
    // 안 된다 (여정 테스트가 잡은 실결함) — 컨트롤러 변화에 구독한다.
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        container.settings,
        container.progress,
        container.profile,
      ]),
      builder: (BuildContext context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final AppSettings st = container.settings.settings;

    return Scaffold(
      appBar: AppBar(
        // 버전은 늘 보인다 (하우스 규칙)
        title: Text('SVIL Baduk  v$appVersion'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: S.menuHelp(_lang),
            onPressed: () => _showHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: S.settings(_lang),
            onPressed: () => _push(context, SettingsScreen(container: container)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(S.tagline(_lang), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          _profileCard(context),
          const SizedBox(height: 16),
          _tile(
            context,
            icon: Icons.smart_toy_outlined,
            label: S.solo(_lang),
            detail: '${st.rankId} · ${st.boardSize.lines}${S.rowSuffix(_lang)}',
            onTap: () => _push(context, SoloSetupScreen(container: container)),
          ),
          _tile(
            context,
            icon: Icons.school_outlined,
            label: S.learn(_lang),
            detail: '${container.progress.solved.length} / '
                '${container.curriculum.problemCount}',
            onTap: () => _push(
              context,
              LearnScreen(
                curriculum: container.curriculum,
                settings: st,
                vision: container.vision.vision,
                solved: container.progress.solved,
                onProgress: container.progress.save,
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.groups_outlined,
            label: S.menuMulti(_lang),
            detail: '${S.hostRoom(_lang)} · ${S.joinRoom(_lang)}',
            onTap: () => _push(
                context,
                MultiScreen(
                    container: container,
                    makeEndpoint: container.makeEndpoint)),
          ),
          _tile(
            context,
            icon: Icons.face_outlined,
            label: S.menuCharacter(_lang),
            detail: _recordLine(),
            onTap: () => _push(context, CharacterScreen(container: container)),
          ),
          _tile(
            context,
            icon: Icons.tune,
            label: S.settings(_lang),
            detail: langLabels[_lang]!,
            onTap: () => _push(context, SettingsScreen(container: container)),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  String _recordLine() {
    final Profile p = container.profile.profile;
    return '${p.wins}${S.winSuffix(_lang)} ${p.losses}${S.lossSuffix(_lang)} '
        '${p.draws}${S.drawSuffix(_lang)}';
  }

  /// 별명·급수·레벨·전적·경험치 요약 — Stitch 홈의 프로필 카드
  Widget _profileCard(BuildContext context) {
    return ListenableBuilder(
      listenable: container.profile,
      builder: (BuildContext context, _) {
        final Profile p = container.profile.profile;
        final Grade grade = gradeForBestAi(p.bestAiLevel);
        final int need = xpToNextLevel(p.level);
        final TextTheme t = Theme.of(context).textTheme;
        final ColorScheme c = Theme.of(context).colorScheme;

        final String name =
            p.name.isEmpty ? S.profileNamePlaceholder(_lang) : p.name;
        final String summary = '$name, ${gradeLabel(grade, _lang)}, '
            '${S.profileLevel(_lang)} ${p.level}, ${_recordLine()}, '
            '${S.profileXp(_lang)} ${p.xp}/$need';

        return Semantics(
          label: summary,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surfaceContainerHighest,
                border: Border.all(color: c.outline, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(name, style: t.titleLarge)),
                      Text(
                        '${gradeLabel(grade, _lang)} · '
                        '${S.profileLevel(_lang)} ${p.level}',
                        style: monoStyle(size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${S.profileRecord(_lang)} ${_recordLine()}'
                      '   ${S.profileHighScore(_lang)} ${p.highScore}'),
                  const SizedBox(height: 10),
                  Text('${S.profileXp(_lang)}  ${p.xp} / $need',
                      style: t.bodySmall),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: need == 0 ? 0 : p.xp / need,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// SVIL 표준 타일 — 어두운 표면 + 밝은 테두리 + 아이콘 + 두 줄 텍스트.
  /// 모양은 테마(outlinedButtonTheme)가 정하고 여기는 내용만 놓는다.
  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String detail,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // 라벨은 포커스 받는 버튼 안에 병합한다 — 바깥 라벨 + 안쪽 포커스로
      // 갈라지면 Tab 이 침묵한다 (0.16.1 에서 실측로 발견해 고친 패턴)
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(kListItemMin),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
        child: Semantics(
          label: '$label, $detail',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(label),
                      Text(detail,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 도움말 — 조작법 요약. 앱 안에서 언제든 볼 수 있어야 한다 (기획 D8)
  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.menuHelp(_lang)),
        content: SingleChildScrollView(
          child: Text(
            '${S.boardHint(_lang)}\n\n${S.coordInputHelper(_lang)}',
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(kTouchLarge, kTouchLarge)),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.confirm(_lang)),
          ),
        ],
      ),
    );
  }
}
