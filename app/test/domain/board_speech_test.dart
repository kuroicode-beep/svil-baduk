// test/domain/board_speech_test.dart — 낭독 문장
//
// 체크리스트 A6·A13. 문장 규칙 하나가 특히 중요하다:
// 좌표가 항상 맨 앞에 와야 발화가 끊겨도 위치가 전달된다.

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/domain/engine/board.dart';
import 'package:svil_baduk/domain/engine/types.dart';
import 'package:svil_baduk/domain/input/board_speech.dart';

const BoardSpeech speech = BoardSpeech(
  blackWord: '흑',
  whiteWord: '백',
  emptyWord: '빈 점',
  starWord: '화점',
  lastMoveWord: '직전 수',
  libertyWord: '활로',
  turnSuffix: ' 차례',
  captureWord: '점 따냄',
  stoneCountWord: '점',
  noStonesWord: '돌 없음',
  rowWord: '줄',
  noLastMoveWord: '직전 수 없음',
  passWord: '패스',
);

void main() {
  group('지점 낭독', () {
    test('좌표가 항상 문장 맨 앞에 온다', () {
      final GameState g = createGame(BoardSize.s19);
      // 발화가 끊겨도 위치는 전달되어야 한다
      expect(speech.point(g, 3, 3).startsWith('D16'), isTrue);
      expect(speech.point(g, 0, 18).startsWith('A1'), isTrue);
      expect(speech.point(g, 15, 15, detail: SpeechDetail.full).startsWith('Q4'),
          isTrue);
    });

    test('빈 점·돌·화점을 구분한다', () {
      final GameState g = createProblemState(
        size: BoardSize.s19,
        black: const <Point>[Point(3, 3)],
        white: const <Point>[Point(15, 15)],
        toPlay: Stone.black,
      );
      expect(speech.point(g, 3, 3), 'D16, 흑, 화점');
      expect(speech.point(g, 15, 15), 'Q4, 백, 화점');
      expect(speech.point(g, 5, 5), 'F14, 빈 점');
    });

    test('직전 수를 표시한다', () {
      final GameState g = createGame(BoardSize.s19);
      final String s = speech.point(g, 4, 4, lastMove: const Point(4, 4));
      expect(s, contains('직전 수'));
      expect(s.startsWith('E15'), isTrue);
    });

    test('자세히 모드에서 돌의 활로를 센다', () {
      // 모서리에 홀로 있는 흑 — 활로 2
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(0, 0)],
        white: const <Point>[],
        toPlay: Stone.white,
      );
      expect(speech.point(g, 0, 0, detail: SpeechDetail.full), contains('활로 2'));
    });

    test('자세히 모드에서 빈 점의 이웃을 읽는다', () {
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(4, 3)], // 위
        white: const <Point>[Point(5, 4)], // 오른쪽
        toPlay: Stone.black,
      );
      final String s = speech.point(g, 4, 4, detail: SpeechDetail.full);
      expect(s, contains('위 흑'));
      expect(s, contains('오른쪽 백'));
    });

    test('간단 모드는 활로·이웃을 말하지 않는다', () {
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(0, 0)],
        white: const <Point>[],
        toPlay: Stone.white,
      );
      expect(speech.point(g, 0, 0), isNot(contains('활로')));
    });
  });

  group('A6 · 착수 결과', () {
    test('색·좌표·다음 차례를 말한다', () {
      final GameState g = createGame(BoardSize.s19);
      final PlayOk r = tryPlay(g, 3, 3) as PlayOk;
      final String s = speech.moveResult(r.state, r.move);
      expect(s, '흑 D16, 백 차례');
    });

    test('따냄 수를 포함한다', () {
      // 흑이 백 한 점을 따낸다
      GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(1, 0)],
        white: const <Point>[Point(0, 0)],
        toPlay: Stone.black,
      );
      final PlayOk r = tryPlay(g, 0, 1) as PlayOk;
      final String s = speech.moveResult(r.state, r.move);
      expect(s, contains('백 1점 따냄'));
      expect(s.startsWith('흑 A8'), isTrue);
    });
  });

  group('A13 · 줄·요약 질의', () {
    test('한 줄의 돌을 읽는다', () {
      final GameState g = createProblemState(
        size: BoardSize.s9,
        black: const <Point>[Point(0, 0), Point(2, 0)],
        white: const <Point>[Point(4, 0)],
        toPlay: Stone.black,
      );
      // 9줄 판의 y=0 은 9줄
      final String s = speech.row(g, 9);
      expect(s, contains('A 흑'));
      expect(s, contains('C 흑'));
      expect(s, contains('E 백'));
    });

    test('빈 줄을 알린다', () {
      final GameState g = createGame(BoardSize.s9);
      expect(speech.row(g, 5), contains('돌 없음'));
    });

    test('판 요약에 돌 수와 차례가 들어간다', () {
      final GameState g = createProblemState(
        size: BoardSize.s19,
        black: const <Point>[Point(3, 3), Point(4, 4)],
        white: const <Point>[Point(15, 15)],
        toPlay: Stone.white,
      );
      final String s = speech.summary(g, lastMove: const Point(4, 4));
      expect(s, contains('19줄 판'));
      expect(s, contains('흑 2점'));
      expect(s, contains('백 1점'));
      expect(s, contains('직전 수 E15'));
      expect(s, contains('백 차례'));
    });

    test('직전 수가 없으면 그렇게 말한다', () {
      expect(speech.summary(createGame(BoardSize.s9)), contains('직전 수 없음'));
    });
  });
}
