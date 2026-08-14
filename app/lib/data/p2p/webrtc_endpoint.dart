// lib/data/p2p/webrtc_endpoint.dart — flutter_webrtc 로 P2PTransport 구현
//
// 시그널링은 PeerBroker(PeerJS 프로토콜), 실데이터는 WebRTC DataChannel.
// 게스트가 offer 를 만들고 호스트가 answer 한다 (PeerJS 관례와 동일).
// STUN 만 쓴다 — 엄격한 NAT 에서는 실패할 수 있고, 그 사실은 로비 문구
// (p2pHint)에 이미 적혀 있다.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/p2p/transport.dart';
import 'peer_broker.dart';

const Map<String, dynamic> _rtcConfig = <String, dynamic>{
  'iceServers': <Map<String, dynamic>>[
    <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
  ],
};

const Duration _answerTimeout = Duration(seconds: 15);
const Duration _channelTimeout = Duration(seconds: 15);

/// 공개 PeerJS 클라우드는 payload 를 스키마로 검증하고, 안 맞으면 소켓을
/// 조용히 닫는다(실측 2026-08-14: 필드가 빠진 OFFER → 즉시 close 1000/1011).
/// 그래서 공식 클라이언트와 같은 필드 집합을 그대로 보낸다 —
/// serialization 값은 우리 쪽에서는 쓰지 않는 시그널링 메타데이터다.
Map<String, dynamic> _offerPayload(
        String connectionId, Map<String, dynamic> sdp) =>
    <String, dynamic>{
      'sdp': sdp,
      'type': 'data',
      'connectionId': connectionId,
      'label': connectionId,
      'reliable': true,
      'serialization': 'binary',
    };

Map<String, dynamic> _answerPayload(
        String connectionId, Map<String, dynamic> sdp) =>
    <String, dynamic>{
      'sdp': sdp,
      'type': 'data',
      'connectionId': connectionId,
    };

Map<String, dynamic> _candidatePayload(
        String connectionId, Map<String, dynamic> candidate) =>
    <String, dynamic>{
      'candidate': candidate,
      'type': 'data',
      'connectionId': connectionId,
    };

class WebRtcTransport implements P2PTransport {
  WebRtcTransport(this._pc, this._channel) {
    _channel.onMessage = (RTCDataChannelMessage m) {
      if (!m.isBinary) _events.add(TransportMessage(m.text));
    };
    _channel.onDataChannelState = (RTCDataChannelState s) {
      if (s == RTCDataChannelState.RTCDataChannelClosed) {
        _emitClosed('disconnected');
      }
    };
    // 채널보다 연결 자체가 먼저 죽는 경우 (상대 프로세스 종료 등).
    // 15초 내 끊김 감지(체크리스트 P4)는 ICE 의 disconnected 전이가 담당한다.
    _pc.onConnectionState = (RTCPeerConnectionState s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _emitClosed('disconnected');
      }
    };
  }

  final RTCPeerConnection _pc;
  final RTCDataChannel _channel;
  final StreamController<TransportEvent> _events =
      StreamController<TransportEvent>.broadcast();
  bool _closed = false;

  void _emitClosed(String reasonKey) {
    if (_closed) return;
    _closed = true;
    if (!_events.isClosed) {
      _events.add(TransportClosed(reasonKey));
      _events.close();
    }
  }

  @override
  Stream<TransportEvent> get events => _events.stream;

  @override
  void send(String text) {
    unawaited(_channel.send(RTCDataChannelMessage(text)));
  }

  @override
  Future<void> close() async {
    _emitClosed('disconnected');
    await _channel.close();
    await _pc.close();
  }
}

class WebRtcEndpoint implements P2PEndpoint {
  WebRtcEndpoint({PeerBroker? broker}) : _broker = broker ?? PeerBroker();

  final PeerBroker _broker;
  String _myId = '';

  final StreamController<P2PTransport> _incoming =
      StreamController<P2PTransport>.broadcast();

  /// 진행 중인 연결 시도 — src 별로 후보(candidate)를 흘려 넣는다
  final Map<String, RTCPeerConnection> _pending = <String, RTCPeerConnection>{};

  /// answer 를 기다리는 게스트 시도
  final Map<String, Completer<Map<String, dynamic>>> _awaitingAnswer =
      <String, Completer<Map<String, dynamic>>>{};

  StreamSubscription<BrokerSignal>? _sub;

  @override
  Stream<P2PTransport> get incoming => _incoming.stream;

  @override
  Future<String> open({String? preferredId}) async {
    _myId = preferredId ?? generateRoomId();
    await _broker.open(_myId);
    _sub = _broker.signals.listen(_onSignal);
    return _myId;
  }

  void _onSignal(BrokerSignal sig) {
    switch (sig.type) {
      case 'OFFER':
        unawaited(_acceptOffer(sig.src, sig.payload ?? <String, dynamic>{}));
      case 'ANSWER':
        _awaitingAnswer.remove(sig.src)?.complete(
            sig.payload ?? <String, dynamic>{});
      case 'CANDIDATE':
        final RTCPeerConnection? pc = _pending[sig.src];
        final Map<String, dynamic>? c =
            (sig.payload?['candidate'] as Map?)?.cast<String, dynamic>();
        if (pc != null && c != null) {
          unawaited(pc.addCandidate(RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          )));
        }
      case 'EXPIRE':
        // 상대 방이 없다 — 게스트 시도가 있으면 실패로 끝낸다
        _awaitingAnswer.remove(sig.src)?.completeError(
            const P2PException('connectFailed', detail: 'peer unavailable'));
      default:
        break;
    }
  }

  Future<RTCPeerConnection> _newPeer(String remoteId, String connectionId) async {
    final RTCPeerConnection pc = await createPeerConnection(_rtcConfig);
    _pending[remoteId] = pc;
    pc.onIceCandidate = (RTCIceCandidate c) {
      _broker.sendSignal(
          'CANDIDATE',
          remoteId,
          _candidatePayload(connectionId, <String, dynamic>{
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          }));
    };
    return pc;
  }

  static String _newConnectionId() =>
      'dc_${generateRoomId().substring(4)}${DateTime.now().millisecondsSinceEpoch % 1000}';

  /// 게스트 경로 — offer 를 만들어 보내고 answer·채널 열림을 기다린다
  @override
  Future<P2PTransport> connect(String remoteId) async {
    final String dst = remoteId.trim().toLowerCase();
    if (dst.isEmpty) throw const P2PException('connectFailed', detail: 'empty id');

    final String connectionId = _newConnectionId();
    final RTCPeerConnection pc = await _newPeer(dst, connectionId);
    try {
      final RTCDataChannel channel = await pc.createDataChannel(
          'baduk', RTCDataChannelInit()..ordered = true);

      final Completer<Map<String, dynamic>> answer =
          Completer<Map<String, dynamic>>();
      _awaitingAnswer[dst] = answer;

      final RTCSessionDescription offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _broker.sendSignal(
          'OFFER',
          dst,
          _offerPayload(connectionId,
              <String, dynamic>{'sdp': offer.sdp, 'type': offer.type}));

      final Map<String, dynamic> ansPayload;
      try {
        ansPayload = await answer.future.timeout(_answerTimeout);
      } on TimeoutException {
        throw const P2PException('connectFailed', detail: 'answer timeout');
      }
      final Map<String, dynamic> sdp =
          (ansPayload['sdp'] as Map).cast<String, dynamic>();
      await pc.setRemoteDescription(RTCSessionDescription(
          sdp['sdp'] as String?, sdp['type'] as String?));

      await _waitChannelOpen(channel);
      return WebRtcTransport(pc, channel);
    } on Object {
      _pending.remove(dst);
      _awaitingAnswer.remove(dst);
      await pc.close();
      rethrow;
    }
  }

  /// 호스트 경로 — 들어온 offer 에 answer 하고 채널을 받는다
  Future<void> _acceptOffer(String src, Map<String, dynamic> payload) async {
    try {
      final String connectionId =
          payload['connectionId'] as String? ?? _newConnectionId();
      final RTCPeerConnection pc = await _newPeer(src, connectionId);
      final Completer<RTCDataChannel> channelReady =
          Completer<RTCDataChannel>();
      pc.onDataChannel = (RTCDataChannel ch) {
        if (!channelReady.isCompleted) channelReady.complete(ch);
      };

      final Map<String, dynamic> sdp =
          (payload['sdp'] as Map).cast<String, dynamic>();
      await pc.setRemoteDescription(RTCSessionDescription(
          sdp['sdp'] as String?, sdp['type'] as String?));
      final RTCSessionDescription answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _broker.sendSignal(
          'ANSWER',
          src,
          _answerPayload(connectionId,
              <String, dynamic>{'sdp': answer.sdp, 'type': answer.type}));

      final RTCDataChannel channel;
      try {
        channel = await channelReady.future.timeout(_channelTimeout);
      } on TimeoutException {
        await pc.close();
        _pending.remove(src);
        return; // 상대가 도중에 떠났다 — 호스트는 계속 기다린다
      }
      await _waitChannelOpen(channel);
      _incoming.add(WebRtcTransport(pc, channel));
    } on Object catch (e) {
      // 손님 하나의 실패가 방을 무너뜨리면 안 된다 — 기록만 남긴다
      assert(() {
        // ignore: avoid_print
        print('acceptOffer failed: $e — ${jsonEncode(payload)}');
        return true;
      }());
      _pending.remove(src);
    }
  }

  static Future<void> _waitChannelOpen(RTCDataChannel ch) async {
    if (ch.state == RTCDataChannelState.RTCDataChannelOpen) return;
    final Completer<void> opened = Completer<void>();
    ch.onDataChannelState = (RTCDataChannelState s) {
      if (s == RTCDataChannelState.RTCDataChannelOpen &&
          !opened.isCompleted) {
        opened.complete();
      }
    };
    try {
      await opened.future.timeout(_channelTimeout);
    } on TimeoutException {
      throw const P2PException('connectFailed', detail: 'channel open timeout');
    } finally {
      // WebRtcTransport 가 자기 핸들러를 다시 건다
      ch.onDataChannelState = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    for (final RTCPeerConnection pc in _pending.values) {
      try {
        await pc.close();
      } on Object catch (_) {
        // 전송 쪽에서 이미 닫혔을 수 있다 — 정리 실패로 죽지 않는다
      }
    }
    _pending.clear();
    await _broker.close();
    if (!_incoming.isClosed) await _incoming.close();
  }
}
