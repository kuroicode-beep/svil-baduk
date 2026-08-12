// test/domain/katago_test.dart — 체크리스트 K2·K4·K5·K9
//
// 프로세스를 띄우지 않고 검증 가능한 부분: GTP 프레이밍, 오류 분류, 증분 동기화.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/platform/katago_process.dart';

void main() {
  group('GTP 응답 파싱', () {
    test('성공 응답에서 payload 를 꺼낸다', () {
      expect((parseGtpBlock('= D4') as GtpOk).payload, 'D4');
      expect((parseGtpBlock('=') as GtpOk).payload, '');
      expect((parseGtpBlock('= KataGo') as GtpOk).payload, 'KataGo');
    });

    test('거부 응답을 구분한다', () {
      final GtpResponse r = parseGtpBlock('? invalid command');
      expect(r, isA<GtpRejected>());
      expect((r as GtpRejected).message, 'invalid command');
    });

    test('빈 블록을 구분한다 — 조용히 성공으로 넘기지 않는다', () {
      expect(parseGtpBlock(''), isA<GtpEmpty>());
      expect(parseGtpBlock('   \n  '), isA<GtpEmpty>());
    });

    test('앞에 잡음이 있어도 응답 줄을 찾는다', () {
      expect((parseGtpBlock('noise\n= ok') as GtpOk).payload, 'ok');
    });

    test('CRLF 응답을 견딘다 — Windows 대상이다', () {
      expect((parseGtpBlock('= D4\r') as GtpOk).payload, 'D4');
    });
  });

  group('K4·K5 · 증분 보드 동기화', () {
    test('공통 접두사 길이를 센다', () {
      expect(
        historyPrefixMatch(
          <String>['B D4', 'W Q16'],
          <String>['B D4', 'W Q16', 'B Q4'],
        ),
        2,
      );
    });

    test('분기하면 그 지점에서 멈춘다 — 전체 재동기화 신호', () {
      expect(
        historyPrefixMatch(
          <String>['B D4', 'W Q16'],
          <String>['B D4', 'W D16'],
        ),
        1,
      );
    });

    test('빈 이력', () {
      expect(historyPrefixMatch(<String>[], <String>['B D4']), 0);
      expect(historyPrefixMatch(<String>['B D4'], <String>[]), 0);
    });

    test('100수 대국이면 이어붙일 수만 보낸다', () {
      // K4: 수마다 재동기화하면 명령이 폭증한다
      final List<String> engine =
          List<String>.generate(99, (int i) => 'move $i');
      final List<String> wanted =
          List<String>.generate(100, (int i) => 'move $i');
      final int common = historyPrefixMatch(engine, wanted);
      expect(common, 99);
      expect(wanted.length - common, 1, reason: '새 수 하나만 보내야 합니다');
    });
  });

  group('K2 · 오류 분류', () {
    test('오류 종류가 서로 구별된다', () {
      // UI 가 사유별로 다른 문장을 낭독할 수 있어야 한다
      expect(KataGoError.values.toSet().length, KataGoError.values.length);
      expect(KataGoError.values.length, greaterThanOrEqualTo(8));
    });

    test('예외가 어떤 명령에서 났는지 담는다', () {
      const KataGoException e = KataGoException(KataGoError.timeout, 'genmove B');
      expect(e.toString(), contains('timeout'));
      expect(e.toString(), contains('genmove B'));
    });
  });

  group('K9 · 브리지 잔재가 없다', () {
    test('실행 중이 아니면 notRunning 으로 즉시 거부한다', () async {
      final KataGoProcess p = KataGoProcess();
      expect(p.isRunning, isFalse);
      await expectLater(
        p.send('name'),
        throwsA(isA<KataGoException>().having(
            (KataGoException e) => e.error, 'error', KataGoError.notRunning)),
      );
      await p.dispose();
    });
  });

  group('경로 탐색', () {
    test('실행 파일이 없으면 어느 경로인지 알려준다', () {
      expect(
        () => KataGoPaths.resolve(root: 'no/such/dir'),
        throwsA(isA<KataGoException>().having(
            (KataGoException e) => e.error, 'error', KataGoError.exeMissing)),
      );
    });
  });
}
