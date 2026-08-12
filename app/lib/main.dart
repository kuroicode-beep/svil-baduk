// lib/main.dart — SVIL Baduk (Flutter)

import 'package:flutter/material.dart';

import 'application/app_container.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/svil_theme.dart';

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
          home: ListenableBuilder(
            // 설정이 바뀌면 화면도 따라간다 (언어·판 색 등)
            listenable: container.settings,
            builder: (BuildContext context, _) =>
                HomeScreen(container: container),
          ),
        );
      },
    );
  }
}
