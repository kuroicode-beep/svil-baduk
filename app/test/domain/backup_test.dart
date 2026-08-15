// test/domain/backup_test.dart — 데이터 이전 (체크리스트 D5)
//
// React src/data/backup.ts 가 만드는 실제 형식의 파일을 물려
// 설정·프로필·배우기 진행이 Flutter 컨트롤러까지 도달하는지 본다.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svil_baduk/application/app_container.dart';
import 'package:svil_baduk/domain/backup.dart';
import 'package:svil_baduk/domain/engine/scoring.dart';
import 'package:svil_baduk/domain/engine/types.dart';

/// React buildBackup('0.9.1') 출력과 같은 모양
const String reactBackup = '''
{
  "format": "svil-baduk-backup",
  "version": 1,
  "appVersion": "0.9.1",
  "savedAt": "2026-08-15T00:00:00.000Z",
  "data": {
    "svil-baduk-settings": {"v": 3, "fontSize": "large", "boardSize": 13,
      "goRules": "chinese", "lang": "ja"},
    "svil-baduk-profile": {"name": "웹돌이", "level": 4, "xp": 10,
      "wins": 7, "losses": 3, "draws": 1, "highScore": 55,
      "bestAiLevel": 6, "gamesPlayed": 11},
    "svil-baduk-learn-progress": ["basics-1-1", "basics-1-2"],
    "svil-baduk-solo-prefs": {"whatever": true}
  }
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeBackup', () {
    test('형식·버전을 검증한다', () {
      expect(decodeBackup('not json'),
          isA<BackupFail>().having((BackupFail f) => f.reasonKey, 'reason',
              'importFailedNotJson'));
      expect(decodeBackup('{"format":"other"}'),
          isA<BackupFail>().having((BackupFail f) => f.reasonKey, 'reason',
              'importFailedNotBackup'));
      expect(
          decodeBackup(
              '{"format":"svil-baduk-backup","version":99,"data":{}}'),
          isA<BackupFail>().having((BackupFail f) => f.reasonKey, 'reason',
              'importFailedVersion'));
    });

    test('React 파일에서 세 키를 원문 형태로 되살린다', () {
      final BackupOk ok = decodeBackup(reactBackup) as BackupOk;
      expect(ok.appVersion, '0.9.1');
      expect(ok.values.keys, unorderedEquals(kBackupKeys));
      // solo-prefs 는 Flutter 저장소가 없어 버려진다
      expect(ok.values.containsKey('svil-baduk-solo-prefs'), isFalse);
    });
  });

  test('D5 · 가져오기가 설정·프로필·진행을 컨트롤러까지 되살린다', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final AppContainer c =
        await AppContainer.create(prefs: await SharedPreferences.getInstance());

    final (String result, int n) = await c.importBackup(reactBackup);
    expect(result, 'importDone');
    expect(n, 3, reason: 'solo-prefs 를 뺀 세 키');

    // 설정 — React 문자열 폰트 크기가 마이그레이션된다 (large → 20)
    expect(c.settings.settings.boardSize, BoardSize.s13);
    expect(c.settings.settings.goRules, GoRules.chinese);
    expect(c.settings.settings.lang.code, 'ja');
    expect(c.vision.vision.baseFontSize, 20);
    // 프로필
    expect(c.profile.profile.name, '웹돌이');
    expect(c.profile.profile.wins, 7);
    expect(c.profile.profile.bestAiLevel, 6);
    // 배우기 진행
    expect(c.progress.solved, containsAll(<String>['basics-1-1', 'basics-1-2']));
  });

  test('잘못된 파일은 아무것도 바꾸지 않는다', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'svil-baduk-profile': '{"name":"원래","level":1,"xp":0,"wins":0,'
          '"losses":0,"draws":0,"highScore":0,"bestAiLevel":0,"gamesPlayed":0}',
    });
    final AppContainer c =
        await AppContainer.create(prefs: await SharedPreferences.getInstance());
    final (String result, _) = await c.importBackup('{"format":"nope"}');
    expect(result, 'importFailedNotBackup');
    expect(c.profile.profile.name, '원래');
  });

  test('내보내기 → 가져오기 왕복 · React restoreBackup 형식', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final AppContainer c =
        await AppContainer.create(prefs: await SharedPreferences.getInstance());
    c.profile.setName('왕복이');
    c.progress.save(<String>{'basics-1-1'});

    final String exported = c.exportBackup(appVersion: '0.20.0');
    final Map<String, dynamic> j =
        (jsonDecode(exported) as Map).cast<String, dynamic>();
    expect(j['format'], 'svil-baduk-backup');
    expect(j['version'], 1);
    expect((j['data'] as Map)['svil-baduk-profile'], isA<Map<dynamic, dynamic>>(),
        reason: 'React 는 값이 JSON 객체이길 기대한다 (문자열이면 이중 인코딩)');

    // 새 컨테이너에 왕복
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final AppContainer c2 =
        await AppContainer.create(prefs: await SharedPreferences.getInstance());
    expect((await c2.importBackup(exported)).$1, 'importDone');
    expect(c2.profile.profile.name, '왕복이');
    expect(c2.progress.solved, contains('basics-1-1'));
  });
}
