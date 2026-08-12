// test/domain/learn_progress_test.dart — 진행 저장 (L6)

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/db/learn_progress_store.dart';

void main() {
  test('왕복', () {
    final Set<String> ids = <String>{'b1-p1', 'b2-p3', 'f1-p2'};
    expect(decodeLearnProgress(encodeLearnProgress(ids)), ids);
  });

  test('순서가 달라도 같은 문자열 — 백업 비교가 시끄러워지지 않게', () {
    expect(
      encodeLearnProgress(<String>{'c', 'a', 'b'}),
      encodeLearnProgress(<String>{'b', 'c', 'a'}),
    );
  });

  test('빈 진행', () {
    expect(decodeLearnProgress(encodeLearnProgress(<String>{})), isEmpty);
    expect(decodeLearnProgress(null), isEmpty);
    expect(decodeLearnProgress(''), isEmpty);
  });

  test('v0 (배열만 저장하던 형식) 을 읽는다', () {
    expect(decodeLearnProgress('["a","b"]'), <String>{'a', 'b'});
  });

  test('손상된 값은 빈 집합 — 깨진 값으로 스테이지를 잠그지 않는다', () {
    for (final String bad in <String>['{{{', 'null', '42', '{"solved":5}']) {
      expect(decodeLearnProgress(bad), isEmpty, reason: bad);
    }
  });

  test('문자열이 아닌 항목은 걸러낸다', () {
    expect(decodeLearnProgress('{"v":1,"solved":["a",3,null,"b"]}'),
        <String>{'a', 'b'});
  });

  test('React 판과 같은 저장 키를 쓴다 — 백업 호환', () {
    expect(kLearnProgressKey, 'svil-baduk-learn-progress');
  });
}
