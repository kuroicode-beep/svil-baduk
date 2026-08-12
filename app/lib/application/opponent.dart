// lib/application/opponent.dart — 상대편이 수를 내는 통로
//
// 내장 AI 와 KataGo 를 같은 모양으로 다룬다. 화면은 어느 쪽인지 모른다.
//
// 접근성상 중요한 점: 상대의 수는 포커스가 어디에 있든 1초 안에 낭독돼야
// 한다(체크리스트 A7). 그래서 결과를 기다리는 동안에도 화면이 멈추면 안 되고,
// 실패하면 조용히 넘어가는 대신 이유가 있는 결과를 돌려준다.

import '../domain/ai/builtin.dart';
import '../domain/ai/ranks.dart';
import '../domain/engine/types.dart';

sealed class OpponentReply {
  const OpponentReply();
}

/// 둘 자리를 냈다
final class OpponentMove extends OpponentReply {
  const OpponentMove(this.point);
  final Point point;
}

/// 둘 곳이 없다 — 패스한다
final class OpponentPass extends OpponentReply {
  const OpponentPass();
}

/// 엔진이 답하지 못했다. [reasonKey] 는 i18n 키다.
final class OpponentFailed extends OpponentReply {
  const OpponentFailed(this.reasonKey, {this.detail});
  final String reasonKey;
  final String? detail;
}

abstract class Opponent {
  /// 이 국면에서 둘 수. 호출자는 결과를 기다리는 동안 판을 바꾸지 않는다.
  Future<OpponentReply> nextMove(GameState state);

  /// 화면에 표시할 이름의 i18n 키
  String get labelKey;

  void dispose() {}
}

/// KataGo 없이 도는 상대. 저레벨은 탐색을 안 하므로 즉시 답한다.
class BuiltinOpponent implements Opponent {
  BuiltinOpponent(this.rankId);

  final String rankId;

  @override
  String get labelKey => getRank(rankId).labelKey;

  @override
  Future<OpponentReply> nextMove(GameState state) async {
    // 상위 레벨은 19줄에서 수백 ms 가 걸린다. 이벤트 루프를 한 번 넘겨
    // 착수 낭독이 먼저 나가게 한다 — 사용자에게는 그 순서가 중요하다.
    await Future<void>.delayed(Duration.zero);
    final Point? p = pickBuiltinMove(state, rankId);
    return p == null ? const OpponentPass() : OpponentMove(p);
  }

  @override
  void dispose() {}
}

/// 주 엔진이 실패하면 예비 엔진으로 넘어간다 (체크리스트 K7).
///
/// 한 번 넘어가면 되돌아오지 않는다. KataGo 가 죽은 뒤 매 수 재시도하면
/// 그때마다 90초 타임아웃을 기다리게 되고, 그건 멈춘 것과 구별되지 않는다.
class FallbackOpponent implements Opponent {
  FallbackOpponent({
    required this.primary,
    required this.backup,
    this.onFallback,
  });

  final Opponent primary;
  final Opponent backup;

  /// 강등이 일어났음을 화면에 알린다 — 조용히 바뀌면 안 된다
  final void Function(String reasonKey, String? detail)? onFallback;

  bool _fellBack = false;

  bool get usingBackup => _fellBack;

  @override
  String get labelKey => _fellBack ? backup.labelKey : primary.labelKey;

  @override
  Future<OpponentReply> nextMove(GameState state) async {
    if (_fellBack) return backup.nextMove(state);

    final OpponentReply r = await primary.nextMove(state);
    if (r is! OpponentFailed) return r;

    _fellBack = true;
    onFallback?.call(r.reasonKey, r.detail);
    primary.dispose();
    return backup.nextMove(state);
  }

  @override
  void dispose() {
    if (!_fellBack) primary.dispose();
    backup.dispose();
  }
}
