// lib/ui/widgets/board/board_announcer.dart — Flutter 접근성 결함을 흡수하는 층
//
// 규칙 하나하나가 확인된 결함의 우회책이다. 바꾸기 전에 이유를 읽을 것.
//
//  1. 커서 이동은 Semantics.value 로만 보낸다. announce 계열을 쓰지 않는다.
//     announce 는 웹에서 300ms 뒤 문자열을 지우고, 같은 문구 연속 발화를 막으려
//     공백을 번갈아 붙인다. 빠른 커서 이동에서 안내가 유실된다.
//     value 변경은 타이머가 아니라 이벤트(MSAA VALUECHANGE)라 이 문제를 비켜간다.
//  2. Semantics(liveRegion: true) 는 엔진에서 Assertiveness.polite 로 하드코딩돼
//     있어 반칙 알림에 쓸 수 없다. CI 테스트가 사용을 금지한다.
//  3. SemanticsService.announce 는 3.35 이후 deprecated — sendAnnouncement 를 쓴다.

import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/semantics.dart';

/// 무엇을 언제 내보냈는지 — 스크린리더 음성 로그와 대조하기 위한 기록
class AnnounceRecord {
  const AnnounceRecord(this.at, this.channel, this.text);
  final DateTime at;
  final String channel;
  final String text;
}

class BoardAnnouncer {
  BoardAnnouncer({
    required this.onValue,
    this.coalesce = const Duration(milliseconds: 120),
    this.keepLog = false,
  });

  /// Semantics.value 에 쓰는 콜백
  final void Function(String) onValue;

  /// 커서 연타를 묶는 창
  final Duration coalesce;
  final bool keepLog;

  /// announce 계열에 필요하다. 화면이 붙을 때 채워 넣는다.
  FlutterView? view;

  final List<AnnounceRecord> log = <AnnounceRecord>[];

  Timer? _timer;
  String? _pending;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// 마지막으로 내보낸 문장 — 'r'(다시) 명령이 읽는다
  String lastSpoken = '';

  /// 커서 이동 — 리딩 엣지 즉시 + 트레일링 디바운스.
  /// 첫 입력은 바로 들리고, 연타는 최종 지점만 들린다.
  void cursor(String text) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastEmit) >= coalesce) {
      _emit(text);
      return;
    }
    _pending = text;
    _timer?.cancel();
    _timer = Timer(coalesce, () {
      final String? p = _pending;
      _pending = null;
      if (p != null) _emit(p);
    });
  }

  void _emit(String text) {
    _lastEmit = DateTime.now();
    lastSpoken = text;
    if (keepLog) log.add(AnnounceRecord(_lastEmit, 'value', text));
    onValue(text);
  }

  /// 상대 착수·따냄 같은 사건
  void event(String text) {
    lastSpoken = text;
    if (keepLog) log.add(AnnounceRecord(DateTime.now(), 'event', text));
    _send(text, Assertiveness.polite);
  }

  /// 반칙·종국 등 즉시 들려야 하는 것
  void critical(String text) {
    lastSpoken = text;
    if (keepLog) log.add(AnnounceRecord(DateTime.now(), 'critical', text));
    _send(text, Assertiveness.assertive);
  }

  void _send(String text, Assertiveness assertiveness) {
    final FlutterView? v = view;
    if (v == null) return;
    SemanticsService.sendAnnouncement(
      v,
      text,
      TextDirection.ltr,
      assertiveness: assertiveness,
    );
  }

  /// 대기 중인 커서 발화를 즉시 내보낸다 (착수 직전 등)
  void flush() {
    _timer?.cancel();
    final String? p = _pending;
    _pending = null;
    if (p != null) _emit(p);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
