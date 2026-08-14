// test_live/broker_live_test.dart — 공개 PeerJS 브로커 실측 (수동 실행)
//
// CI 에 네트워크를 넣지 않으려고 test/ 밖에 있다. 실행:
//   flutter test test_live/broker_live_test.dart
//
// 검증: 등록(OPEN) 10초 내 · 두 클라이언트 간 시그널 중계 왕복 ·
// 없는 상대는 침묵이 아니라 감지 가능(스파이크 기준 1의 시그널링 절반).

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/p2p/peer_broker.dart';
import 'package:svil_baduk/domain/p2p/transport.dart';

// 클라우드는 payload 를 스키마로 검증한다 — 필드가 빠지면 소켓을 닫는다
// (실측 2026-08-14). 앱과 같은 형태를 보낸다.
const String _fakeSdp = 'v=0\r\n'
    'o=- 1 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n'
    'm=application 9 UDP/DTLS/SCTP webrtc-datachannel\r\nc=IN IP4 0.0.0.0\r\n';

Map<String, dynamic> offerPayload() => <String, dynamic>{
      'sdp': <String, String>{'sdp': _fakeSdp, 'type': 'offer'},
      'type': 'data',
      'connectionId': 'dc_live1234',
      'label': 'dc_live1234',
      'reliable': true,
      'serialization': 'binary',
    };

Map<String, dynamic> answerPayload() => <String, dynamic>{
      'sdp': <String, String>{'sdp': _fakeSdp, 'type': 'answer'},
      'type': 'data',
      'connectionId': 'dc_live1234',
    };

void main() {
  test('실서버 — 등록 두 건과 OFFER/ANSWER 중계 왕복', () async {
    final String idA = generateRoomId();
    final String idB = generateRoomId();
    final PeerBroker a = PeerBroker();
    final PeerBroker b = PeerBroker();

    final Stopwatch sw = Stopwatch()..start();
    await a.open(idA);
    await b.open(idB);
    final int openMs = sw.elapsedMilliseconds;
    expect(openMs, lessThan(10000), reason: '등록이 10초를 넘었다');

    // A → B 로 OFFER, B → A 로 ANSWER (payload 는 서버가 열어보지 않는다)
    final Future<BrokerSignal> bGets = b.signals
        .firstWhere((BrokerSignal s) => s.type == 'OFFER')
        .timeout(const Duration(seconds: 10));
    a.sendSignal('OFFER', idB, offerPayload());
    final BrokerSignal offer = await bGets;
    expect(offer.src, idA);
    expect(offer.payload!['connectionId'], 'dc_live1234');

    final Future<BrokerSignal> aGets = a.signals
        .firstWhere((BrokerSignal s) => s.type == 'ANSWER')
        .timeout(const Duration(seconds: 10));
    b.sendSignal('ANSWER', idA, answerPayload());
    final BrokerSignal answer = await aGets;
    expect(answer.src, idB);
    expect(answer.payload!['connectionId'], 'dc_live1234');

    // ignore: avoid_print
    print('실서버 왕복 성공 — 등록 ${openMs}ms, 중계 왕복 ${sw.elapsedMilliseconds}ms');
    await a.close();
    await b.close();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('실서버 — 없는 상대에게 보낸 시그널은 EXPIRE 로 돌아온다', () async {
    final PeerBroker a = PeerBroker();
    await a.open(generateRoomId());

    final Future<BrokerSignal> expire = a.signals
        .firstWhere((BrokerSignal s) => s.type == 'EXPIRE')
        .timeout(const Duration(seconds: 20));
    a.sendSignal('OFFER', 'svb-nobody9', offerPayload());
    final BrokerSignal got = await expire;
    expect(got.type, 'EXPIRE');
    await a.close();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
