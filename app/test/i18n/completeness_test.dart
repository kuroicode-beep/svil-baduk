// test/i18n/completeness_test.dart — 체크리스트 I1·I2·I3
//
// 조용한 폴백을 막는다. 번역이 비면 빌드가 아니라 테스트가 잡는다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/i18n/strings.g.dart';

void main() {
  test('I1 · 5개 언어가 모두 있고 빈 값이 없다', () {
    final List<String> empty = <String>[];
    for (final MapEntry<String, LocString> e in allStrings.entries) {
      for (final Lang l in Lang.values) {
        if (e.value(l).trim().isEmpty) empty.add('${e.key}.${l.code}');
      }
    }
    expect(empty, isEmpty, reason: '빈 번역이 있습니다');
  });

  test('I3 · 키 개수가 충분하다', () {
    expect(allStrings.length, generatedStringCount);
    expect(allStrings.length, greaterThanOrEqualTo(155),
        reason: 'React 판 155키가 최소선입니다');
  });

  test('언어 코드와 라벨이 짝을 이룬다', () {
    for (final Lang l in Lang.values) {
      expect(langLabels[l], isNotNull, reason: '${l.code} 라벨 없음');
      expect(langLabels[l]!.isNotEmpty, isTrue);
    }
    expect(Lang.fromCode('ko'), Lang.ko);
    expect(Lang.fromCode('vi'), Lang.vi);
    // 모르는 코드는 한국어로
    expect(Lang.fromCode('xx'), Lang.ko);
  });

  test('한국어가 아닌 언어도 실제로 번역돼 있다 — 한국어 복붙이 아니어야', () {
    // 전부 같으면 번역을 안 한 것이다. 고유명사는 같을 수 있으니 비율로 본다.
    for (final Lang l in <Lang>[Lang.en, Lang.ja, Lang.zh, Lang.vi]) {
      int same = 0;
      for (final LocString s in allStrings.values) {
        if (s(l) == s.ko) same++;
      }
      final double ratio = same / allStrings.length;
      expect(ratio, lessThan(0.3),
          reason: '${l.code} 의 ${(ratio * 100).toStringAsFixed(0)}% 가 '
              '한국어와 동일합니다 — 번역 누락 의심');
    }
  });

  test('핵심 문자열이 존재한다', () {
    expect(S.appTitle(Lang.ko), isNotEmpty);
    expect(S.black(Lang.ko), '흑');
    expect(S.white(Lang.ko), '백');
    expect(S.pass(Lang.ko), isNotEmpty);
    expect(S.resign(Lang.ko), isNotEmpty);
    // 좌표 입력 경로에 필요한 것들
    expect(S.pointEmpty(Lang.ko), isNotEmpty);
    expect(S.confirmPlace(Lang.ko), isNotEmpty);
    expect(S.occupiedPoint(Lang.ko), isNotEmpty);
  });
}
