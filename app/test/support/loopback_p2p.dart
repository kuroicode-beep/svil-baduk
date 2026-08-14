// test/support/loopback_p2p.dart — 네트워크 없는 P2P 전송
//
// 실제 스택과 같은 인터페이스(P2PEndpoint/P2PTransport)를 메모리 안에서
// 구현한다. 컨트롤러·화면 테스트가 핸드셰이크부터 대국까지 전부 돌린다.

import 'dart:async';

import 'package:svil_baduk/domain/p2p/transport.dart';

class LoopbackTransport implements P2PTransport {
  LoopbackTransport(this._label);

  final String _label;
  LoopbackTransport? peer;
  bool closed = false;

  /// true 로 두면 다음 send 하나를 떨어뜨린다 — 재동기화 테스트용
  bool dropNext = false;

  final List<String> sent = <String>[];
  final StreamController<TransportEvent> _events =
      StreamController<TransportEvent>.broadcast();

  @override
  Stream<TransportEvent> get events => _events.stream;

  @override
  void send(String text) {
    sent.add(text);
    if (dropNext) {
      dropNext = false;
      return;
    }
    final LoopbackTransport? p = peer;
    if (p == null || p.closed) return;
    // 실제 채널처럼 비동기로 배달한다
    scheduleMicrotask(() {
      if (!p.closed && !p._events.isClosed) {
        p._events.add(TransportMessage(text));
      }
    });
  }

  /// 상대가 보낸 것처럼 밀어 넣는다 — 프로토콜 위반 주입용
  void inject(String text) {
    if (!_events.isClosed) _events.add(TransportMessage(text));
  }

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    if (!_events.isClosed) {
      _events.add(const TransportClosed('disconnected'));
      await _events.close();
    }
    final LoopbackTransport? p = peer;
    if (p != null && !p.closed) await p.close();
  }

  @override
  String toString() => 'LoopbackTransport($_label)';

  static (LoopbackTransport, LoopbackTransport) pair() {
    final LoopbackTransport a = LoopbackTransport('a');
    final LoopbackTransport b = LoopbackTransport('b');
    a.peer = b;
    b.peer = a;
    return (a, b);
  }
}

/// 같은 프로세스 안의 방 등록부 — FakeEndpoint 끼리 서로를 찾는다
class FakeBrokerRegistry {
  final Map<String, FakeEndpoint> _rooms = <String, FakeEndpoint>{};
}

class FakeEndpoint implements P2PEndpoint {
  FakeEndpoint(this.registry, {this.fixedId});

  final FakeBrokerRegistry registry;
  final String? fixedId;
  String myId = '';

  final StreamController<P2PTransport> _incoming =
      StreamController<P2PTransport>.broadcast();

  /// 이 엔드포인트가 만든 전송들 — 테스트가 조작할 수 있게 남겨 둔다
  final List<LoopbackTransport> transports = <LoopbackTransport>[];

  @override
  Stream<P2PTransport> get incoming => _incoming.stream;

  @override
  Future<String> open({String? preferredId}) async {
    myId = preferredId ?? fixedId ?? generateRoomId();
    registry._rooms[myId] = this;
    return myId;
  }

  @override
  Future<P2PTransport> connect(String remoteId) async {
    final FakeEndpoint? remote = registry._rooms[remoteId.trim()];
    if (remote == null || identical(remote, this)) {
      throw const P2PException('connectFailed', detail: 'peer unavailable');
    }
    final (LoopbackTransport near, LoopbackTransport far) =
        LoopbackTransport.pair();
    transports.add(near);
    remote.transports.add(far);
    remote._incoming.add(far);
    return near;
  }

  @override
  Future<void> dispose() async {
    registry._rooms.remove(myId);
    for (final LoopbackTransport t in transports) {
      await t.close();
    }
    if (!_incoming.isClosed) await _incoming.close();
  }
}
