// lib/domain/backup.dart — React 판 백업 파일 해석 (체크리스트 D5)
//
// React 웹(0.9.1+)의 "내 데이터 내보내기" 가 만든 JSON 을 읽는다.
// 형식 정본은 src/data/backup.ts — 버전 있는 한 덩어리가 두 구현 사이의
// 유일한 이전 경로다. 각 키의 내용 검증·마이그레이션은 원래 로더가 한다
// (settings 는 migrateSettings, profile 은 decodeProfile).

import 'dart:convert';

const String kBackupFormat = 'svil-baduk-backup';
const int kBackupVersion = 1;

/// 백업에 담기는 키 — React BACKUP_KEYS 와 동일해야 한다.
/// solo-prefs 는 Flutter 에 대응 저장소가 없어 무시된다.
const List<String> kBackupKeys = <String>[
  'svil-baduk-settings',
  'svil-baduk-profile',
  'svil-baduk-learn-progress',
];

sealed class BackupResult {
  const BackupResult();
}

/// 키 → 저장소에 그대로 쓸 JSON 문자열
final class BackupOk extends BackupResult {
  const BackupOk(this.values, {required this.appVersion});
  final Map<String, String> values;
  final String appVersion;
}

final class BackupFail extends BackupResult {
  const BackupFail(this.reasonKey);

  /// i18n 키: importFailedNotJson · importFailedNotBackup · importFailedVersion
  final String reasonKey;
}

BackupResult decodeBackup(String text) {
  final Object? parsed;
  try {
    parsed = jsonDecode(text);
  } on Object catch (_) {
    return const BackupFail('importFailedNotJson');
  }
  if (parsed is! Map) return const BackupFail('importFailedNotBackup');
  final Map<String, dynamic> j = parsed.cast<String, dynamic>();

  if (j['format'] != kBackupFormat) {
    return const BackupFail('importFailedNotBackup');
  }
  final Object? version = j['version'];
  if (version is! int || version > kBackupVersion) {
    return const BackupFail('importFailedVersion');
  }
  final Object? data = j['data'];
  if (data is! Map) return const BackupFail('importFailedNotBackup');

  final Map<String, String> values = <String, String>{};
  for (final String key in kBackupKeys) {
    final Object? v = data[key];
    if (v == null) continue;
    // localStorage 원문과 같은 형태로 되돌린다 — 로더가 그 형태를 기대한다
    values[key] = jsonEncode(v);
  }
  return BackupOk(values, appVersion: j['appVersion'] as String? ?? '');
}

/// Flutter 쪽 내보내기 — React restoreBackup 이 그대로 읽을 수 있는 형식
String encodeBackup({
  required String appVersion,
  required String savedAt,
  required Map<String, String> storedValues,
}) {
  final Map<String, Object?> data = <String, Object?>{};
  for (final MapEntry<String, String> e in storedValues.entries) {
    try {
      data[e.key] = jsonDecode(e.value);
    } on Object catch (_) {
      // 손상된 값은 조용히 건너뛴다 — 백업이 실패하는 것보다 낫다 (React 판과 동일)
    }
  }
  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'format': kBackupFormat,
    'version': kBackupVersion,
    'appVersion': appVersion,
    'savedAt': savedAt,
    'data': data,
  });
}
