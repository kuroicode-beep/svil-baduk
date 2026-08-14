// lib/domain/p2p/transport.dart — 전송 계층 인터페이스 (순수 Dart)
//
// 구현은 data/p2p/(브로커·WebRTC), 테스트는 루프백 쌍을 쓴다.
// 화면·컨트롤러는 이 인터페이스만 알고, 밑이 WebRTC 인지 모른다.

import 'dart:async';
import 'dart:math';

/// 전송에서 올라오는 사건
sealed class TransportEvent {
  const TransportEvent();
}

/// 데이터 채널이 열렸다 — 이제 [P2PTransport.send] 가 상대에게 닿는다
final class TransportConnected extends TransportEvent {
  const TransportConnected();
}

/// 상대가 보낸 한 줄 (JSON 문자열)
final class TransportMessage extends TransportEvent {
  const TransportMessage(this.text);
  final String text;
}

/// 연결이 끊어졌다. [reasonKey] 는 i18n 키다 — 화면이 번역해 낭독한다.
final class TransportClosed extends TransportEvent {
  const TransportClosed(this.reasonKey, {this.detail});
  final String reasonKey;
  final String? detail;
}

/// 상대 하나와의 양방향 문자열 통로
abstract class P2PTransport {
  Stream<TransportEvent> get events;
  void send(String text);
  Future<void> close();
}

/// 방을 열고(호스트) 상대 방으로 들어가는(게스트) 진입점
abstract class P2PEndpoint {
  /// 브로커에 등록하고 내 방 ID 를 돌려준다
  Future<String> open({String? preferredId});

  /// 상대 방으로 접속한다 (게스트 경로)
  Future<P2PTransport> connect(String remoteId);

  /// 상대가 들어오면 흘러나온다 (호스트 경로)
  Stream<P2PTransport> get incoming;

  Future<void> dispose();
}

/// 전송 계층의 실패. [reasonKey] 는 i18n 키 — 원문 대신 번역이 낭독된다.
class P2PException implements Exception {
  const P2PException(this.reasonKey, {this.detail});
  final String reasonKey;
  final String? detail;

  @override
  String toString() => 'P2PException($reasonKey${detail == null ? '' : ': $detail'})';
}

/// 사람이 한 글자씩 읽고 옮겨 적을 수 있는 방 ID.
///
/// 혼동 문자(0/O, 1/I/l)를 뺀 소문자·숫자만 쓴다 — 체크리스트 P6 의
/// "한 글자씩 낭독" 이 성립하려면 대소문자 구별이 없어야 한다.
String generateRoomId({Random? random}) {
  const String alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
  final Random r = random ?? Random.secure();
  final StringBuffer b = StringBuffer('svb-');
  for (int i = 0; i < 6; i++) {
    b.write(alphabet[r.nextInt(alphabet.length)]);
  }
  return b.toString();
}
