// test/ui/layout_overflow_test.dart — 체크리스트 V7·V8·V9·I4
//
// Flutter 는 CSS 처럼 reflow 하지 않는다. 글자를 키우면 줄바꿈 대신 **넘친다**.
// 저시력 앱에서 배율 3배는 예외가 아니라 기본 사용 조건이라, 넘침은
// "가끔 나는 경고"가 아니라 기능 실패다.
//
// 렌더 트리에서 넘침을 직접 잡는다. Flutter 는 넘칠 때 콘솔에 노란 줄무늬와
// 함께 예외를 던지는데, 테스트에서는 그 예외를 모아 판정한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/learn/curriculum.dart';
import 'package:svil_baduk/domain/platform_caps.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/screens/character_screen.dart';
import 'package:svil_baduk/ui/screens/home_screen.dart';
import 'package:svil_baduk/ui/screens/learn_screen.dart';
import 'package:svil_baduk/ui/screens/settings_screen.dart';
import 'package:svil_baduk/ui/screens/solo_screen.dart';
import 'package:svil_baduk/ui/screens/solo_setup_screen.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';

/// 체크리스트가 정한 조합
const List<double> kScales = <double>[1.0, 1.5, 2.0, 3.0];
const List<double> kWidths = <double>[800, 1280, 1920];

/// 넘침 예외만 모은다. 다른 예외는 그대로 실패시킨다.
class _OverflowCatcher {
  final List<String> overflows = <String>[];
  void Function(FlutterErrorDetails)? _previous;

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String text = d.exceptionAsString();
      if (text.contains('overflowed by')) {
        overflows.add(text.split('\n').first);
      } else {
        _previous?.call(d);
      }
    };
  }

  void stop() => FlutterError.onError = _previous;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Curriculum curriculum;

  setUpAll(() {
    curriculum = Curriculum.parse(
        File('assets/learn/curriculum.json').readAsStringSync());
  });

  Future<AppContainer> boot(WidgetTester tester) async {
    final AppContainer? c = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return AppContainer.create(prefs: await SharedPreferences.getInstance());
    });
    return c!;
  }

  /// 한 화면을 주어진 크기·배율로 그리고 넘침을 센다
  Future<List<String>> render(
    WidgetTester tester,
    Widget screen, {
    required double width,
    required double scale,
  }) async {
    final _OverflowCatcher catcher = _OverflowCatcher()..start();
    try {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(
          theme: buildBadukTheme(const VisionSettings()),
          home: screen,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      catcher.stop();
    }
    return catcher.overflows;
  }

  // 이 테스트가 없으면 위의 모든 테스트가 "아무것도 안 잡아서" 통과할 수 있다.
  // 감지기가 실제로 넘침을 본다는 것을 먼저 증명한다.
  testWidgets('⚠ 감지기 자체 검증 — 일부러 넘치게 하면 잡힌다',
      (WidgetTester tester) async {
    final List<String> o = await render(
      tester,
      // 300px 폭 안에 2000px 짜리를 억지로 넣는다
      const Scaffold(
        body: SizedBox(
          width: 300,
          child: Row(
            children: <Widget>[SizedBox(width: 2000, height: 20)],
          ),
        ),
      ),
      width: 300,
      scale: 1.0,
    );
    expect(o, isNotEmpty,
        reason: '넘침 감지기가 동작하지 않습니다 — 위 테스트들이 전부 공허합니다');
    expect(o.first, contains('overflowed by'));
  });

  group('V7 · 배율 × 창 너비 12조합에서 넘침 0', () {
    for (final double scale in kScales) {
      for (final double width in kWidths) {
        testWidgets('시작 화면 · 배율 $scale · 폭 ${width.toInt()}',
            (WidgetTester tester) async {
          final AppContainer c = await boot(tester);
          final List<String> o = await render(
              tester, HomeScreen(container: c),
              width: width, scale: scale);
          expect(o, isEmpty, reason: o.join(' | '));
        });

        testWidgets('설정 화면 · 배율 $scale · 폭 ${width.toInt()}',
            (WidgetTester tester) async {
          final AppContainer c = await boot(tester);
          final List<String> o = await render(
              tester, SettingsScreen(container: c),
              width: width, scale: scale);
          expect(o, isEmpty, reason: o.join(' | '));
        });

        testWidgets('대국 화면 · 배율 $scale · 폭 ${width.toInt()}',
            (WidgetTester tester) async {
          final List<String> o = await render(
            tester,
            SoloScreen(
              settings: const AppSettings(opponent: OpponentKind.none),
              vision: const AppSettings().toVision(systemReduceMotion: false),
              size: BoardSize.s19,
              caps: const PlatformCaps(AppPlatform.windows),
            ),
            width: width,
            scale: scale,
          );
          expect(o, isEmpty, reason: o.join(' | '));
        });
      }
    }
  });

  group('V8 · 큰 글자에서 세로로 쌓인다', () {
    testWidgets('배율 3배 · 좁은 창에서도 판과 조작부가 모두 그려진다',
        (WidgetTester tester) async {
      final List<String> o = await render(
        tester,
        SoloScreen(
          settings: const AppSettings(opponent: OpponentKind.none),
          vision: const AppSettings(fontSize: 32)
              .toVision(systemReduceMotion: false),
          size: BoardSize.s19,
          caps: const PlatformCaps(AppPlatform.windows),
        ),
        width: 800,
        scale: 3.0,
      );
      expect(o, isEmpty, reason: o.join(' | '));
      // 세로 스택으로 내려가도 조작 버튼은 살아 있어야 한다
      expect(find.text(S.pass(Lang.ko)), findsOneWidget);
    });
  });

  group('I4 · 5개 언어 × 배율 2배에서 넘침 0', () {
    for (final Lang lang in Lang.values) {
      testWidgets('시작 화면 · ${lang.code}', (WidgetTester tester) async {
        final AppContainer c = await boot(tester);
        c.settings.update(c.settings.settings.copyWith(lang: lang));
        final List<String> o = await render(tester, HomeScreen(container: c),
            width: 1280, scale: 2.0);
        expect(o, isEmpty, reason: '${lang.code}: ${o.join(' | ')}');
      });

      testWidgets('설정 화면 · ${lang.code}', (WidgetTester tester) async {
        final AppContainer c = await boot(tester);
        c.settings.update(c.settings.settings.copyWith(lang: lang));
        final List<String> o = await render(
            tester, SettingsScreen(container: c),
            width: 1280, scale: 2.0);
        expect(o, isEmpty, reason: '${lang.code}: ${o.join(' | ')}');
      });

      testWidgets('배우기 · ${lang.code}', (WidgetTester tester) async {
        final List<String> o = await render(
          tester,
          LearnScreen(
            curriculum: curriculum,
            settings: AppSettings(lang: lang),
            vision: const AppSettings().toVision(systemReduceMotion: false),
            solved: const <String>{},
            onProgress: (_) {},
          ),
          width: 1280,
          scale: 2.0,
        );
        expect(o, isEmpty, reason: '${lang.code}: ${o.join(' | ')}');
      });
    }
  });

  group('신규 화면 (0.17.0) — 배율 3배 · 좁은 폭에서 넘침 0', () {
    for (final double scale in <double>[2.0, 3.0]) {
      testWidgets('캐릭터 · 배율 $scale', (WidgetTester tester) async {
        final AppContainer c = await boot(tester);
        final List<String> o = await render(
            tester, CharacterScreen(container: c),
            width: 800, scale: scale);
        expect(o, isEmpty, reason: o.join(' | '));
      });

      testWidgets('대국 설정 · 배율 $scale', (WidgetTester tester) async {
        final AppContainer c = await boot(tester);
        final List<String> o = await render(
            tester, SoloSetupScreen(container: c),
            width: 800, scale: scale);
        expect(o, isEmpty, reason: o.join(' | '));
      });
    }
  });

  group('V9 · 터치 타깃 크기', () {
    /// 실제로 렌더된 크기를 잰다. 지정값이 아니라 결과를 본다.
    List<Size> tappableSizes(WidgetTester tester) => <Size>[
          for (final Element e in <Element>[
            ...tester.elementList(find.byType(OutlinedButton)),
            ...tester.elementList(find.byType(FilledButton)),
            ...tester.elementList(find.byType(ElevatedButton)),
          ])
            tester.getSize(find.byElementPredicate((Element x) => x == e)),
        ];

    testWidgets('대국 화면 버튼이 모두 48dp 이상', (WidgetTester tester) async {
      await render(
        tester,
        SoloScreen(
          settings: const AppSettings(opponent: OpponentKind.none),
          vision: const AppSettings().toVision(systemReduceMotion: false),
          size: BoardSize.s9,
          caps: const PlatformCaps(AppPlatform.windows),
        ),
        width: 1280,
        scale: 1.0,
      );
      final List<Size> sizes = tappableSizes(tester);
      expect(sizes, isNotEmpty, reason: '버튼을 하나도 못 찾았습니다');
      for (final Size s in sizes) {
        expect(s.height, greaterThanOrEqualTo(48.0), reason: '$s');
        expect(s.width, greaterThanOrEqualTo(48.0), reason: '$s');
      }
    });

    testWidgets('확정 착수 버튼은 56dp 이상 — 19줄 교차점이 작기 때문',
        (WidgetTester tester) async {
      await render(
        tester,
        SoloScreen(
          settings: const AppSettings(
              opponent: OpponentKind.none, placeMode: PlaceMode.confirm),
          vision: const AppSettings().toVision(systemReduceMotion: false),
          size: BoardSize.s19,
          caps: const PlatformCaps(AppPlatform.windows),
        ),
        width: 1280,
        scale: 1.0,
      );
      expect(kListItemMin, greaterThanOrEqualTo(56.0),
          reason: '확정 버튼 최소 높이 상수가 56 미만입니다');
    });

    testWidgets('배율을 올려도 버튼이 작아지지 않는다', (WidgetTester tester) async {
      await render(
        tester,
        SoloScreen(
          settings: const AppSettings(opponent: OpponentKind.none),
          vision: const AppSettings().toVision(systemReduceMotion: false),
          size: BoardSize.s9,
          caps: const PlatformCaps(AppPlatform.windows),
        ),
        width: 1280,
        scale: 2.0,
      );
      for (final Size s in tappableSizes(tester)) {
        expect(s.height, greaterThanOrEqualTo(48.0), reason: '$s');
      }
    });
  });
}
