// test/domain/peer_broker_test.dart — PeerJS 브로커 프로토콜 클라이언트
//
// 가짜 소켓으로 등록·중계·오류·하트비트를 검증한다. 실서버 검증은
// test_live/broker_live_test.dart (수동 실행 — CI 에 네트워크를 넣지 않는다).

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:svil_baduk/data/p2p/peer_broker.dart';
import 'package:svil_baduk/domain/p2p/transport.dart';

class FakeSocket implements BrokerSocket {
  final StreamController<String> incoming = StreamController<String>();
  final List<String> outgoing = <String>[];
  bool closed = false;
  Uri? uri;

  @override
  Stream<String> get messages => incoming.stream;

  @override
  void send(String text) => outgoing.add(text);

  @override
  Future<void> close() async {
    closed = true;
    if (!incoming.isClosed) await incoming.close();
  }

  void serverSays(Map<String, dynamic> j) => incoming.add(jsonEncode(j));
}

(PeerBroker, FakeSocket) make({Duration? heartbeat}) {
  final FakeSocket socket = FakeSocket();
  final PeerBroker broker = PeerBroker(
    connector: (Uri uri) async {
      socket.uri = uri;
      return socket;
    },
    heartbeatInterval: heartbeat,
    openTimeout: const Duration(milliseconds: 200),
  );
  return (broker, socket);
}

void main() {
  test('등록 — OPEN 을 받아야 open() 이 끝난다', () async {
    final (PeerBroker broker, FakeSocket socket) = make();
    final Future<void> opening = broker.open('svb-abc123');
    await pumpEventQueue();
    expect(broker.isOpen, isFalse);
    socket.serverSays(<String, dynamic>{'type': 'OPEN'});
    await opening;
    expect(broker.isOpen, isTrue);

    // 접속 URL 에 id·key 가 실려야 서버가 방을 만든다
    expect(socket.uri!.queryParameters['id'], 'svb-abc123');
    expect(socket.uri!.queryParameters['key'], 'peerjs');
    await broker.close();
  });

  test('ID-TAKEN 은 P2PException 으로 돌아온다', () async {
    final (PeerBroker broker, FakeSocket socket) = make();
    final Future<void> opening = broker.open('svb-dup');
    await pumpEventQueue();
    socket.serverSays(<String, dynamic>{'type': 'ID-TAKEN'});
    await expectLater(opening, throwsA(isA<P2PException>()));
    await broker.close();
  });

  test('OPEN 이 안 오면 타임아웃으로 실패한다 (행 금지)', () async {
    final (PeerBroker broker, _) = make();
    await expectLater(broker.open('svb-mute'), throwsA(isA<P2PException>()));
  });

  test('중계 — OFFER/ANSWER/CANDIDATE 가 시그널 스트림으로 나온다', () async {
    final (PeerBroker broker, FakeSocket socket) = make();
    final Future<void> opening = broker.open('svb-me');
    await pumpEventQueue();
    socket.serverSays(<String, dynamic>{'type': 'OPEN'});
    await opening;

    final List<BrokerSignal> got = <BrokerSignal>[];
    broker.signals.listen(got.add);
    socket.serverSays(<String, dynamic>{
      'type': 'OFFER',
      'src': 'svb-you',
      'payload': <String, dynamic>{'sdp': <String, dynamic>{'type': 'offer'}},
    });
    socket.serverSays(<String, dynamic>{'type': 'EXPIRE', 'src': 'svb-you'});
    await pumpEventQueue();

    expect(got, hasLength(2));
    expect(got.first.type, 'OFFER');
    expect(got.first.src, 'svb-you');
    expect(got.first.payload!['sdp'], isA<Map<String, dynamic>>());
    expect(got.last.type, 'EXPIRE');
    await broker.close();
  });

  test('보내기 — dst·payload 를 서버 형식으로 감싼다', () async {
    final (PeerBroker broker, FakeSocket socket) = make();
    final Future<void> opening = broker.open('svb-me');
    await pumpEventQueue();
    socket.serverSays(<String, dynamic>{'type': 'OPEN'});
    await opening;

    broker.sendSignal('ANSWER', 'svb-you', <String, dynamic>{'a': 1});
    final Map<String, dynamic> sent =
        (jsonDecode(socket.outgoing.last) as Map).cast<String, dynamic>();
    expect(sent['type'], 'ANSWER');
    expect(sent['dst'], 'svb-you');
    expect((sent['payload'] as Map)['a'], 1);
    await broker.close();
  });

  test('하트비트 — 서버가 5초 유휴로 방을 지우지 않게 한다 (P3 기반)',
      () async {
    final (PeerBroker broker, FakeSocket socket) =
        make(heartbeat: const Duration(milliseconds: 20));
    final Future<void> opening = broker.open('svb-me');
    await pumpEventQueue();
    socket.serverSays(<String, dynamic>{'type': 'OPEN'});
    await opening;

    await Future<void>.delayed(const Duration(milliseconds: 70));
    final int beats = socket.outgoing
        .where((String s) => s.contains('HEARTBEAT'))
        .length;
    expect(beats, greaterThanOrEqualTo(2));
    await broker.close();
  });

  test('소켓이 죽으면 시그널 스트림이 닫힌다 — 위에서 끊김을 감지한다',
      () async {
    final (PeerBroker broker, FakeSocket socket) = make();
    final Future<void> opening = broker.open('svb-me');
    await pumpEventQueue();
    socket.serverSays(<String, dynamic>{'type': 'OPEN'});
    await opening;

    bool done = false;
    broker.signals.listen((_) {}, onDone: () => done = true);
    await socket.incoming.close();
    await pumpEventQueue();
    expect(done, isTrue);
    expect(broker.isOpen, isFalse);
  });

  test('방 ID — 혼동 문자가 없고 형식이 고정된다 (P6 기반)', () {
    for (int i = 0; i < 200; i++) {
      final String id = generateRoomId();
      expect(RegExp(r'^svb-[a-z2-9]{6}$').hasMatch(id), isTrue, reason: id);
      expect(id.contains(RegExp('[01ilo]')), isFalse, reason: id);
    }
  });
}
