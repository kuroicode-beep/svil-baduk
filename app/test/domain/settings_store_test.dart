// test/domain/settings_store_test.dart — React 판 store.test.ts 이식 + 확장
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/settings_store.dart';
import 'package:svil_baduk/i18n/strings.g.dart';
import 'package:svil_baduk/ui/theme/board_theme.dart';
import 'package:svil_baduk/ui/theme/svil_theme.dart';

void main() {
  group('저장 스키마', () {
    test('저장할 때 버전을 붙인다', () {
      final Map<String, dynamic> j =
          jsonDecode(settingsToString(const AppSettings())) as Map<String, dynamic>;
      expect(j['v'], settingsVersion);
    });

    test('왕복해도 값이 보존된다', () {
      const AppSettings s = AppSettings(
        lang: Lang.ja,
        fontSize: 20,
        contrast: ContrastProfile.maximum,
        palette: BoardPaletteId.amberBlue,
        goRules: GoRules.chinese,
        placeMode: PlaceMode.confirm,
      );
      final AppSettings back = settingsFromString(settingsToString(s));
      expect(back.lang, Lang.ja);
      expect(back.fontSize, 20);
      expect(back.contrast, ContrastProfile.maximum);
      expect(back.palette, BoardPaletteId.amberBlue);
      expect(back.goRules, GoRules.chinese);
      expect(back.placeMode, PlaceMode.confirm);
    });
  });

  group('v0 마이그레이션 (버전 필드 없음)', () {
    test('켜둔 reduceMotion 은 유지한다', () {
      expect(migrateSettings(<String, dynamic>{'reduceMotion': true}).reduceMotion,
          ReduceMotionSetting.on);
    });

    test("꺼둔(기본값) reduceMotion 은 system 으로 올린다", () {
      // 한 번만 시딩하면 나중에 OS 에서 켠 사용자에게 반영되지 않는다
      expect(migrateSettings(<String, dynamic>{'reduceMotion': false}).reduceMotion,
          ReduceMotionSetting.system);
      expect(migrateSettings(<String, dynamic>{}).reduceMotion,
          ReduceMotionSetting.system);
    });

    test('v1 의 명시적 false 는 존중한다', () {
      expect(
          migrateSettings(<String, dynamic>{'v': 1, 'reduceMotion': false}).reduceMotion,
          ReduceMotionSetting.off);
    });

    test('React 판의 small/medium/large 글자 크기를 숫자로 옮긴다', () {
      expect(migrateSettings(<String, dynamic>{'fontSize': 'small'}).fontSize, 16);
      expect(migrateSettings(<String, dynamic>{'fontSize': 'medium'}).fontSize, 18);
      expect(migrateSettings(<String, dynamic>{'fontSize': 'large'}).fontSize, 20);
    });

    test('React 판의 boardCoords 키 이름을 그대로 읽는다', () {
      // 백업 JSON 호환을 위해 키 이름을 바꾸지 않았다
      expect(migrateSettings(<String, dynamic>{'boardCoords': 'off'}).coordMode,
          CoordMode.off);
    });
  });

  group('손상된 값 방어', () {
    test('모르는 enum 값은 기본값으로', () {
      final AppSettings m = migrateSettings(<String, dynamic>{
        'v': 1,
        'contrast': 'nonsense',
        'palette': 42,
        'boardScale': null,
        'goRules': <String>['array?'],
        'lang': 'xx',
      });
      const AppSettings base = AppSettings();
      expect(m.contrast, base.contrast);
      expect(m.palette, base.palette);
      expect(m.boardScale, base.boardScale);
      expect(m.goRules, base.goRules);
      expect(m.lang, Lang.ko);
    });

    test('말도 안 되는 글자 크기는 기본값으로', () {
      expect(migrateSettings(<String, dynamic>{'fontSize': 9999}).fontSize, 18);
      expect(migrateSettings(<String, dynamic>{'fontSize': -5}).fontSize, 18);
    });

    test('JSON 이 아니거나 깨져도 죽지 않는다', () {
      expect(settingsFromString('{{{').fontSize, 18);
      expect(settingsFromString('').fontSize, 18);
      expect(settingsFromString(null).fontSize, 18);
      expect(migrateSettings('문자열').fontSize, 18);
      expect(migrateSettings(null).fontSize, 18);
    });

    test('모르는 키가 있어도 죽지 않는다', () {
      expect(
          () => migrateSettings(<String, dynamic>{'v': 1, 'futureFlag': true}),
          returnsNormally);
    });
  });

  group('시각 설정 변환', () {
    test('system 은 OS 값을 따른다', () {
      const AppSettings s = AppSettings(reduceMotion: ReduceMotionSetting.system);
      expect(s.toVision(systemReduceMotion: true).reduceMotion, isTrue);
      expect(s.toVision(systemReduceMotion: false).reduceMotion, isFalse);
    });

    test('명시값은 OS 를 무시한다', () {
      const AppSettings on = AppSettings(reduceMotion: ReduceMotionSetting.on);
      const AppSettings off = AppSettings(reduceMotion: ReduceMotionSetting.off);
      expect(on.toVision(systemReduceMotion: false).reduceMotion, isTrue);
      expect(off.toVision(systemReduceMotion: true).reduceMotion, isFalse);
    });
  });
}
