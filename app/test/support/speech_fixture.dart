// test/support/speech_fixture.dart — 테스트용 낭독 어휘 한 벌
//
// 어휘가 늘 때마다 테스트 파일마다 고치지 않도록 여기 한 곳에 둔다.
// 실제 문구는 i18n 에서 오고, 테스트는 문장 조립 규칙만 본다.

import 'package:svil_baduk/domain/input/board_speech.dart';

const BoardSpeech testSpeech = BoardSpeech(
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
  territoryWord: '집',
  komiWord: '덤',
  winsWord: '집 승',
  drawWord: '무승부',
  estimateWord: '추정',
  hintWord: '추천',
  undoneWord: '무름',
);
