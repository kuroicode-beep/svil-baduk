// integration_test/p2p_e2e_test.dart — P2P 전 구간 실측 (실기 실행)
//
//   flutter test integration_test/p2p_e2e_test.dart -d windows
//
// 위젯 테스트가 못 덮는 봉합선을 실물로 검증한다:
// 실 브로커(0.peerjs.com) → 실 flutter_webrtc offer/answer/candidate →
// 실 DataChannel 열림 → 문자열 왕복. 같은 프로세스의 엔드포인트 두 개라
// ICE 는 호스트 후보로 붙는다 — NAT 통과(다른 네트워크 2대)는 사용자 실측 항목.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:svil_baduk/data/p2p/webrtc_endpoint.dart';
import 'package:svil_baduk/domain/p2p/transport.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실 브로커 + 실 WebRTC — 데이터채널 왕복 30초 내', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final WebRtcEndpoint host = WebRtcEndpoint();
      final WebRtcEndpoint guest = WebRtcEndpoint();
      final Stopwatch sw = Stopwatch()..start();

      final String hostId = await host.open();
      await guest.open();

      final Completer<P2PTransport> hostSide = Completer<P2PTransport>();
      host.incoming.listen((P2PTransport t) {
        if (!hostSide.isCompleted) hostSide.complete(t);
      });

      final P2PTransport guestSide = await guest
          .connect(hostId)
          .timeout(const Duration(seconds: 30));
      final P2PTransport hostT =
          await hostSide.future.timeout(const Duration(seconds: 10));
      final int connectMs = sw.elapsedMilliseconds;

      // 양방향 왕복 — 순서 보장까지 확인 (체크리스트 P2 축소판)
      final List<String> atHost = <String>[];
      final List<String> atGuest = <String>[];
      hostT.events.listen((TransportEvent e) {
        if (e is TransportMessage) atHost.add(e.text);
      });
      guestSide.events.listen((TransportEvent e) {
        if (e is TransportMessage) atGuest.add(e.text);
      });

      for (int i = 0; i < 10; i++) {
        guestSide.send('g$i');
        hostT.send('h$i');
      }
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(atHost, List<String>.generate(10, (int i) => 'g$i'),
          reason: '게스트→호스트 10건이 순서대로 도착해야 한다');
      expect(atGuest, List<String>.generate(10, (int i) => 'h$i'),
          reason: '호스트→게스트 10건이 순서대로 도착해야 한다');

      // 끊김 감지 — 한쪽을 닫으면 상대에게 TransportClosed 가 간다 (P4)
      final Completer<void> closedSeen = Completer<void>();
      hostT.events.listen((TransportEvent e) {
        if (e is TransportClosed && !closedSeen.isCompleted) {
          closedSeen.complete();
        }
      });
      await guestSide.close();
      await closedSeen.future.timeout(const Duration(seconds: 15));

      // ignore: avoid_print
      print('E2E OK — 연결 ${connectMs}ms, 총 ${sw.elapsedMilliseconds}ms');
      await host.dispose();
      await guest.dispose();
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
