// lib/data/db/learn_progress_store.dart — 배우기 진행 저장
//
// React 판(svil-baduk-learn-progress)과 같은 형식을 유지한다.
// 백업 JSON 이 양쪽에서 호환돼야 하므로 키 이름을 바꾸지 않는다.

import 'dart:convert';

/// localStorage / shared_preferences 키 — React 판과 동일
const String kLearnProgressKey = 'svil-baduk-learn-progress';

const int kLearnProgressVersion = 1;

/// 푼 문제 id 집합을 저장 문자열로.
///
/// 정렬해서 쓴다 — 순서만 달라진 파일이 매번 "바뀐 것" 으로 보이면
/// 동기화·백업 비교가 시끄러워진다.
String encodeLearnProgress(Set<String> solved) {
  final List<String> ids = solved.toList()..sort();
  return jsonEncode(<String, Object?>{
    'v': kLearnProgressVersion,
    'solved': ids,
  });
}

/// 저장 문자열에서 집합으로. 손상됐으면 빈 집합이다 —
/// 진행이 사라지는 건 아쉽지만, 깨진 값으로 스테이지를 잠그는 것보다 낫다.
Set<String> decodeLearnProgress(String? text) {
  if (text == null || text.isEmpty) return <String>{};
  try {
    final Object? raw = jsonDecode(text);

    // v0: 배열만 저장하던 형식
    if (raw is List) return raw.whereType<String>().toSet();

    if (raw is! Map) return <String>{};
    final Object? solved = raw['solved'];
    if (solved is! List) return <String>{};
    return solved.whereType<String>().toSet();
  } catch (_) {
    return <String>{};
  }
}
