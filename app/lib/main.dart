// lib/main.dart — SVIL Baduk (Flutter)
//
// 1단계 스캐폴드. 화면은 3단계부터 붙는다.

import 'package:flutter/material.dart';

import 'application/app_container.dart';
import 'domain/changelog.dart';
import 'ui/theme/svil_theme.dart';
import 'version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppContainer container = await AppContainer.create();
  runApp(SvilBadukApp(container: container));
}

class SvilBadukApp extends StatelessWidget {
  const SvilBadukApp({required this.container, super.key});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: container.vision,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'SVIL Baduk',
          debugShowCheckedModeBanner: false,
          theme: buildBadukTheme(container.vision.vision),
          home: ScaffoldMessenger(child: _ScaffoldHome(container: container)),
        );
      },
    );
  }
}

/// 스캐폴드 확인용 임시 화면 — 3단계에서 홈 화면으로 교체된다.
class _ScaffoldHome extends StatelessWidget {
  const _ScaffoldHome({required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final HistoryEntry latest = changelog.first;
    return Scaffold(
      appBar: AppBar(title: const Text('SVIL Baduk')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('SVIL Baduk', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('저시력자를 위한 고대비 바둑',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('v$appVersion', style: monoStyle(size: 18)),
            const SizedBox(height: 24),
            Text('최근 변경 — v${latest.version} (${latest.date})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final String line in latest.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $line'),
              ),
            const Spacer(),
            Text('히스토리 ${changelog.length}개 버전 이식됨',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
