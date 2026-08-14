// lib/data/p2p/peer_broker.dart — PeerJS 브로커 프로토콜을 말하는 클라이언트
//
// peerdart 는 총 다운로드 426회·자칭 알파라 쓰지 않는다(가드레일 T7).
// 서버 프로토콜은 단순하다: WebSocket 등록(OPEN) + OFFER/ANSWER/CANDIDATE
// 중계 + 5초 HEARTBEAT. payload 는 서버가 열어보지 않고 그대로 전달하므로
// 우리 쪽 형식(평문 JSON)을 쓴다 — React 판(BinaryPack)과의 교차 대국은
// 지원하지 않는다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../domain/p2p/transport.dart';

/// 브로커가 중계해 준 시그널 (OFFER/ANSWER/CANDIDATE/LEAVE/EXPIRE)
class BrokerSignal {
  const BrokerSignal({required this.type, required this.src, this.payload});
  final String type;
  final String src;
  final Map<String, dynamic>? payload;
}

/// WebSocket 을 감싼 통로 — 테스트가 가짜를 끼운다
abstract class BrokerSocket {
  Stream<String> get messages;
  void send(String text);
  Future<void> close();
}

typedef BrokerConnector = Future<BrokerSocket> Function(Uri uri);

class _IoBrokerSocket implements BrokerSocket {
  _IoBrokerSocket(this._ws);
  final WebSocket _ws;

  @override
  Stream<String> get messages =>
      _ws.where((dynamic d) => d is String).cast<String>();

  @override
  void send(String text) => _ws.add(text);

  @override
  Future<void> close() => _ws.close();
}

Future<BrokerSocket> _ioConnect(Uri uri) async =>
    _IoBrokerSocket(await WebSocket.connect(uri.toString()));

/// PeerJS 공개 브로커(0.peerjs.com) 기본값. 죽으면 사다리:
/// Railway 에 peerjs-server 자체 호스팅 → 자체 WebSocket 시그널링.
class PeerBroker {
  PeerBroker({
    this.host = '0.peerjs.com',
    this.port = 443,
    this.key = 'peerjs',
    this.secure = true,
    BrokerConnector? connector,
    Duration? heartbeatInterval,
    Duration? openTimeout,
  })  : _connect = connector ?? _ioConnect,
        _heartbeatInterval = heartbeatInterval ?? const Duration(seconds: 5),
        _openTimeout = openTimeout ?? const Duration(seconds: 10);

  final String host;
  final int port;
  final String key;
  final bool secure;
  final BrokerConnector _connect;
  final Duration _heartbeatInterval;
  final Duration _openTimeout;

  BrokerSocket? _socket;
  Timer? _heartbeat;
  StreamSubscription<String>? _sub;
  bool _open = false;
  bool _disposed = false;

  final StreamController<BrokerSignal> _signals =
      StreamController<BrokerSignal>.broadcast();

  /// 서버가 준 시그널 스트림 — 소켓이 죽으면 스트림도 닫힌다
  Stream<BrokerSignal> get signals => _signals.stream;

  bool get isOpen => _open;

  /// [id] 로 등록한다. 서버의 OPEN 확인까지 기다린다.
  Future<void> open(String id) async {
    final String token = _randomToken();
    final Uri uri = Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host,
      port: port,
      path: '/peerjs',
      queryParameters: <String, String>{
        'key': key,
        'id': id,
        'token': token,
        'version': '1.5.4',
      },
    );

    try {
      _socket = await _connect(uri);
    } on Object catch (e) {
      throw P2PException('connectFailed', detail: '$e');
    }

    final Completer<void> opened = Completer<void>();
    _sub = _socket!.messages.listen(
      (String raw) => _onMessage(raw, opened),
      onDone: () => _onSocketDead(opened),
      onError: (Object e) => _onSocketDead(opened, e),
    );

    try {
      await opened.future.timeout(_openTimeout);
    } on TimeoutException {
      await close();
      throw const P2PException('connectFailed', detail: 'broker open timeout');
    }

    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      _socket?.send('{"type":"HEARTBEAT"}');
    });
  }

  void _onMessage(String raw, Completer<void> opened) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object catch (_) {
      return; // 브로커가 보낸 잡값은 조용히 버린다 — 프로토콜 밖이다
    }
    if (decoded is! Map) return;
    final Map<String, dynamic> j = decoded.cast<String, dynamic>();
    final String type = j['type'] as String? ?? '';

    switch (type) {
      case 'OPEN':
        _open = true;
        if (!opened.isCompleted) opened.complete();
      case 'ID-TAKEN':
        if (!opened.isCompleted) {
          opened.completeError(
              const P2PException('connectFailed', detail: 'id taken'));
        }
      case 'ERROR':
        final String msg =
            (j['payload'] as Map<String, dynamic>?)?['msg'] as String? ?? '';
        if (!opened.isCompleted) {
          opened.completeError(P2PException('connectFailed', detail: msg));
        } else {
          _signals.add(BrokerSignal(type: 'ERROR', src: '', payload:
              <String, dynamic>{'msg': msg}));
        }
      case 'OFFER' || 'ANSWER' || 'CANDIDATE' || 'LEAVE' || 'EXPIRE':
        _signals.add(BrokerSignal(
          type: type,
          src: j['src'] as String? ?? '',
          payload: (j['payload'] as Map?)?.cast<String, dynamic>(),
        ));
      default:
        break; // 모르는 종류는 무시 — 서버가 새 종류를 추가해도 죽지 않는다
    }
  }

  void _onSocketDead(Completer<void> opened, [Object? error]) {
    _open = false;
    if (!opened.isCompleted) {
      opened.completeError(
          P2PException('connectFailed', detail: error?.toString()));
    }
    if (!_disposed && !_signals.isClosed) _signals.close();
  }

  /// OFFER/ANSWER/CANDIDATE 를 [dst] 에게 중계해 달라고 보낸다
  void sendSignal(String type, String dst, Map<String, dynamic> payload) {
    _socket?.send(jsonEncode(<String, dynamic>{
      'type': type,
      'dst': dst,
      'payload': payload,
    }));
  }

  Future<void> close() async {
    _disposed = true;
    _heartbeat?.cancel();
    await _sub?.cancel();
    await _socket?.close();
    if (!_signals.isClosed) await _signals.close();
    _open = false;
  }

  static String _randomToken() {
    final Random r = Random.secure();
    return List<String>.generate(
        16, (_) => r.nextInt(36).toRadixString(36)).join();
  }
}
