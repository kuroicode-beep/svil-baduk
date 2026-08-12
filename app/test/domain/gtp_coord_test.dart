// test/domain/gtp_coord_test.dart
//
// 이 파일이 존재하는 이유: React 판에서 좌표 뒤집기가 두 번 일어나
// 서로를 가렸다. pointLabel 이 위아래를 뒤집어 놓았고 GTP 파싱이
// 그 정확한 역함수여서, 왕복은 완벽하게 맞고 KataGo 는 거울 판에서
// 두고 있었다. 그래서 왕복 테스트만으로는 부족하고 **알려진 값**을
// 못박아야 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/gtp_coord.dart';
import 'package:svil_baduk/domain/engine/types.dart';

void main() {
  group('알려진 값 (왕복만으로는 못 잡는다)', () {
    test('19줄 좌상 화점은 D16 이다', () {
      expect(toGtpCoord(3, 3, 19), 'D16');
      expect(parseGtpCoord('D16', 19), const Point(3, 3));
    });

    test('19줄 우하 화점은 Q4 이다', () {
      expect(toGtpCoord(15, 15, 19), 'Q4');
      expect(parseGtpCoord('Q4', 19), const Point(15, 15));
    });

    test('맨 아래 왼쪽이 A1, 맨 위 왼쪽이 A19', () {
      expect(toGtpCoord(0, 18, 19), 'A1');
      expect(toGtpCoord(0, 0, 19), 'A19');
    });

    test('I 를 건너뛴다 — H 다음은 J', () {
      expect(toGtpCoord(7, 0, 19), 'H19');
      expect(toGtpCoord(8, 0, 19), 'J19');
      expect(parseGtpCoord('I5', 19), isNull, reason: 'I 열은 존재하지 않는다');
    });

    test('pointLabel 과 같은 좌표계를 쓴다', () {
      // 둘이 어긋나면 화면에 말하는 좌표와 엔진에 보내는 좌표가 달라진다
      for (final int lines in <int>[9, 13, 19]) {
        for (int y = 0; y < lines; y++) {
          for (int x = 0; x < lines; x++) {
            expect(toGtpCoord(x, y, lines), pointLabel(x, y, lines),
                reason: '$lines줄 ($x,$y)');
          }
        }
      }
    });
  });

  group('왕복', () {
    test('세 판 크기의 모든 점', () {
      for (final int lines in <int>[9, 13, 19]) {
        for (int y = 0; y < lines; y++) {
          for (int x = 0; x < lines; x++) {
            expect(parseGtpCoord(toGtpCoord(x, y, lines), lines), Point(x, y),
                reason: '$lines줄 ($x,$y)');
          }
        }
      }
    });

    test('소문자도 받는다', () {
      expect(parseGtpCoord('d16', 19), const Point(3, 3));
      expect(parseGtpCoord(' q4 ', 19), const Point(15, 15));
    });
  });

  group('패스·기권·오류를 구별한다', () {
    test('pass 와 resign 은 좌표가 아니다', () {
      expect(isGtpPass('pass'), isTrue);
      expect(isGtpPass('PASS'), isTrue);
      expect(isGtpResign('resign'), isTrue);
      expect(parseGtpCoord('pass', 19), isNull);
      expect(parseGtpCoord('resign', 19), isNull);
    });

    test('범위 밖·쓰레기 입력은 null', () {
      expect(parseGtpCoord('T20', 19), isNull, reason: '20줄은 없다');
      expect(parseGtpCoord('U1', 19), isNull, reason: 'U 열은 없다');
      expect(parseGtpCoord('K1', 9), isNull, reason: '9줄에 K 열은 없다');
      expect(parseGtpCoord('A0', 19), isNull);
      expect(parseGtpCoord('', 19), isNull);
      expect(parseGtpCoord('아무거나', 19), isNull);
      expect(parseGtpCoord('DD', 19), isNull);
    });
  });

  group('착수 명령', () {
    test('색과 좌표가 들어간다', () {
      final GameState g = createGame(BoardSize.s19);
      final GameState after = (tryPlay(g, 3, 3) as PlayOk).state;
      expect(gtpPlayCommand(after.history.single, 19), 'play B D16');
    });

    test('패스는 좌표 대신 pass', () {
      final GameState g = createGame(BoardSize.s9);
      final GameState after = (passMove(g) as PlayOk).state;
      expect(gtpPlayCommand(after.history.single, 9), 'play B pass');
    });
  });
}
