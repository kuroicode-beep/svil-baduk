// lib/application/katago_opponent.dart — KataGo 를 상대로 쓴다
//
// Node 브리지·HTTP·CORS 없이 dart:io Process 와 직결한다.
//
// 판 동기화는 증분이다. 수마다 clear_board 를 보내면 GPU 에서도 체감될 만큼
// 느리다(React 판 katago.ts 주석의 근거). 엔진이 이미 아는 수순과 우리 수순의
// 공통 접두사를 찾아 그 뒤만 보낸다.

import 'dart:async';

import '../data/platform/katago_process.dart';
import '../domain/ai/ranks.dart';
import '../domain/engine/gtp_coord.dart';
import '../domain/engine/types.dart';
import 'opponent.dart';

/// KataGoError → i18n 키. 사유가 서로 구별돼야 한다(체크리스트 K2).
String kataGoErrorKey(KataGoError e) => switch (e) {
      KataGoError.exeMissing => 'katagoExeMissing',
      KataGoError.modelMissing => 'katagoModelMissing',
      KataGoError.configMissing => 'katagoConfigMissing',
      KataGoError.notRunning => 'katagoNotRunning',
      KataGoError.exited => 'katagoExited',
      KataGoError.emptyResponse => 'katagoEmptyResponse',
      KataGoError.rejected => 'katagoRejected',
      KataGoError.timeout => 'katagoTimeout',
      KataGoError.startFailed => 'katagoStartFailed',
    };

class KataGoOpponent implements Opponent {
  KataGoOpponent(this.process, this.rankId);

  final GtpChannel process;
  final String rankId;

  /// 엔진이 현재 알고 있는 수순 (GTP 명령 문자열)
  List<String> _engineHistory = <String>[];
  int? _engineLines;

  @override
  String get labelKey => 'engineKataGo';

  @override
  Future<OpponentReply> nextMove(GameState state) async {
    try {
      await _sync(state);
      final String color = state.toPlay == Stone.black ? 'B' : 'W';
      final String raw = await process.genmove(color);

      if (isGtpPass(raw)) {
        _engineHistory.add('play $color pass');
        return const OpponentPass();
      }
      if (isGtpResign(raw)) {
        // 기권은 상대가 졌다는 뜻이지 오류가 아니다. 다만 우리 UI 는
        // 엔진 기권을 아직 다루지 않으므로 패스로 낮춰 받는다.
        return const OpponentPass();
      }

      final Point? p = parseGtpCoord(raw, state.size.lines);
      if (p == null) {
        return OpponentFailed(kataGoErrorKey(KataGoError.rejected), detail: raw);
      }
      _engineHistory.add('play $color ${toGtpCoord(p.x, p.y, state.size.lines)}');
      return OpponentMove(p);
    } on KataGoException catch (e) {
      return OpponentFailed(kataGoErrorKey(e.error),
          detail: e.detail.isEmpty ? null : e.detail);
    }
  }

  /// 공통 접두사 뒤만 보낸다. 분기했으면 그때만 전체 재동기화.
  Future<void> _sync(GameState state) async {
    final int lines = state.size.lines;
    final List<String> wanted = <String>[
      for (final Move m in state.history) gtpPlayCommand(m, lines),
    ];

    // 판 크기가 바뀌었으면 접두사를 비교할 것도 없다
    if (_engineLines != lines) {
      await process.send('boardsize $lines');
      await process.send('clear_board');
      await _applyRankSettings();
      _engineHistory = <String>[];
      _engineLines = lines;
    }

    final int shared = historyPrefixMatch(_engineHistory, wanted);
    if (shared < _engineHistory.length) {
      // 무르기·새 대국 — 갈라진 곳이 있으니 처음부터 다시 (정확히 1회)
      await process.send('clear_board');
      await _applyRankSettings();
      _engineHistory = <String>[];
      for (final String cmd in wanted) {
        await process.send(cmd);
      }
    } else {
      for (int i = shared; i < wanted.length; i++) {
        await process.send(wanted[i]);
      }
    }
    _engineHistory = List<String>.from(wanted);
  }

  /// 난이도를 엔진 쪽 탐색량으로 옮긴다
  Future<void> _applyRankSettings() async {
    final RankOption r = getRank(rankId);
    await process.send('kata-set-param maxVisits ${r.visits}');
  }

  @override
  void dispose() {
    unawaited(process.stop());
  }
}
