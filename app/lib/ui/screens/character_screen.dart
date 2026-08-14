// lib/ui/screens/character_screen.dart — 캐릭터 (별명·급수·레벨·경험치·전적)
//
// Stitch 기획의 프로필 화면 + 사용자 지정 필드(2026-08-14).
// 급수는 저장값이 아니라 bestAiLevel 에서 유도한다 (profile.dart 참조).

import 'package:flutter/material.dart';

import '../../application/app_container.dart';
import '../../domain/profile/profile.dart';
import '../../i18n/strings.g.dart';
import '../theme/svil_theme.dart';

/// 급수를 사람이 읽는 문자열로 — 화면·낭독 공용
String gradeLabel(Grade g, Lang lang) => switch (g) {
      GradeBeginner() => S.gradeBeginner(lang),
      GradeKyu(:final int n) => '$n${S.gradeKyuSuffix(lang)}',
      GradeDan(:final int n) => '$n${S.gradeDanSuffix(lang)}',
    };

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({required this.container, super.key});

  final AppContainer container;

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  late final TextEditingController _name;

  Lang get _lang => widget.container.settings.settings.lang;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: widget.container.profile.profile.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.profileNameRequired(_lang))));
      return;
    }
    widget.container.profile.setName(name);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(S.profileSaved(_lang))));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.container.profile,
      builder: (BuildContext context, _) {
        final Profile p = widget.container.profile.profile;
        final int need = xpToNextLevel(p.level);
        final Grade grade = gradeForBestAi(p.bestAiLevel);
        final TextTheme t = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(title: Text(S.menuCharacter(_lang))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // ── 별명 ─────────────────────────────────────────
              TextField(
                controller: _name,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: S.profileName(_lang),
                  hintText: S.profileNamePlaceholder(_lang),
                  constraints: const BoxConstraints(minHeight: kTouchLarge),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kTouchLarge)),
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(S.profileSave(_lang)),
              ),
              const SizedBox(height: 24),

              // ── 급수 · 레벨 ──────────────────────────────────
              _row(t, S.gradeTitle(_lang), gradeLabel(grade, _lang)),
              _row(t, S.profileLevel(_lang), '${p.level}'),

              // ── 경험치 (진행바 + 수치 병기 — 색·막대만으로 전달 금지) ──
              const SizedBox(height: 8),
              Semantics(
                label:
                    '${S.profileXp(_lang)} ${p.xp} / $need',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${S.profileXp(_lang)}  ${p.xp} / $need',
                          style: t.titleMedium),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: need == 0 ? 0 : p.xp / need,
                          minHeight: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 전적 ─────────────────────────────────────────
              _row(
                t,
                S.profileRecord(_lang),
                '${p.wins}${S.winSuffix(_lang)} '
                '${p.losses}${S.lossSuffix(_lang)} '
                '${p.draws}${S.drawSuffix(_lang)}',
              ),
              _row(t, S.profileHighScore(_lang), '${p.highScore}'),
              _row(t, S.profileBestAi(_lang),
                  p.bestAiLevel == 0 ? '-' : '${p.bestAiLevel}'),
            ],
          ),
        );
      },
    );
  }

  Widget _row(TextTheme t, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: t.titleMedium)),
            Text(value, style: monoStyle(size: 20)),
          ],
        ),
      );
}
