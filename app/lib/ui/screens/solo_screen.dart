// lib/ui/screens/solo_screen.dart — 혼자 두기
//
// 접근성 모델의 조립 지점. 판(포커스 노드 1개) + 좌표 입력(1급 경로) +
// 화면상 쌍둥이 readout + 큰 동작 버튼.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../application/katago_opponent.dart';
import '../../application/opponent.dart';
import '../../data/db/settings_store.dart';
import '../../data/platform/katago_process.dart';
import '../../domain/platform_caps.dart';
import '../../domain/engine/scoring.dart';
import '../../domain/engine/types.dart';
import '../../domain/input/board_speech.dart';
import '../../domain/input/coord_input.dart';
import '../../i18n/strings.g.dart';
import '../theme/board_theme.dart';
import '../theme/svil_theme.dart';
import '../widgets/board/board_announcer.dart';
import '../widgets/board/board_view.dart';
import '../widgets/board/coord_field.dart';
import '../widgets/board/cursor_readout.dart';

/// 언어별 낭독 어휘를 만든다
BoardSpeech speechFor(Lang lang) => BoardSpeech(
      blackWord: S.black(lang),
      whiteWord: S.white(lang),
      emptyWord: S.pointEmpty(lang),
      starWord: S.starPoint(lang),
      lastMoveWord: S.lastMove(lang),
      libertyWord: S.liberties(lang),
      turnSuffix: ' ${S.turnSuffix(lang)}',
      captureWord: S.capturedSuffix(lang),
      stoneCountWord: S.stoneCountSuffix(lang),
      noStonesWord: S.noStones(lang),
      rowWord: S.rowSuffix(lang),
      noLastMoveWord: S.noLastMove(lang),
      passWord: S.pass(lang),
      territoryWord: S.territoryLabel(lang),
      komiWord: S.komiLabel(lang),
      winsWord: S.winsBy(lang),
      drawWord: S.drawResult(lang),
      estimateWord: S.scoreEstimate(lang),
      hintWord: S.hintLabel(lang),
      undoneWord: S.undoneLabel(lang),
    );

String moveErrorPhraseFor(Lang lang, MoveError e) => switch (e) {
      MoveError.occupied => S.errOccupied(lang),
      MoveError.ko => S.errKo(lang),
      MoveError.superko => S.errSuperko(lang),
      MoveError.suicide => S.errSuicide(lang),
      MoveError.gameEnded => S.errGameEnded(lang),
      MoveError.outOfBounds => S.errOutOfBounds(lang),
    };

String coordErrorPhraseFor(Lang lang, CoordError e, int lines) =>
    switch (e.kind) {
      CoordErrorKind.skippedLetter => S.errSkippedLetter(lang),
      CoordErrorKind.badColumn =>
        '${e.detail} — ${S.errBadColumn(lang)} (A~${columnLabel(lines - 1)})',
      CoordErrorKind.badRow =>
        '${e.detail} — ${S.errBadRow(lang)} (1~$lines)',
      CoordErrorKind.empty => S.errEmptyInput(lang),
      CoordErrorKind.unknown => '${e.detail} — ${S.errUnknownInput(lang)}',
    };

class SoloScreen extends StatefulWidget {
  const SoloScreen({
    required this.settings,
    required this.vision,
    required this.size,
    required this.caps,
    super.key,
  });

  final AppSettings settings;
  final VisionSettings vision;
  final BoardSize size;
  final PlatformCaps caps;

  @override
  State<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends State<SoloScreen> {
  late final GameController _game;
  late final BoardAnnouncer _announcer;
  final GlobalKey<BoardViewState> _boardKey = GlobalKey<BoardViewState>();
  final GlobalKey<CoordFieldState> _coordKey = GlobalKey<CoordFieldState>();

  String _value = '';
  String _status = '';

  Opponent? _opponent;

  /// 계가 표시 중일 때의 집 소유. 착수하면 지운다 —
  /// 옛 계가 결과가 판에 남아 있으면 잘못 읽힌다.
  ScoreBreakdown? _score;
  KataGoProcess? _katago;
  StreamSubscription<String>? _tuningSub;

  /// AI 응수를 기다리는 중. 이 동안 사람의 착수를 막는다 —
  /// 두 수가 겹치면 판이 어긋난다.
  bool _thinking = false;

  /// 사람이 쥔 색. 상대가 있을 때만 의미가 있다.
  Player get _humanSide => Stone.black;

  bool get _vsEngine => _opponent != null;

  Lang get _lang => widget.settings.lang;

  @override
  void initState() {
    super.initState();
    _game = GameController(
      size: widget.size,
      speech: speechFor(_lang),
      moveErrorPhrase: (MoveError e) => moveErrorPhraseFor(_lang, e),
      coordErrorPhrase: (CoordError e, int lines) =>
          coordErrorPhraseFor(_lang, e, lines),
      detail: widget.settings.verbosity == AnnounceVerbosity.full
          ? SpeechDetail.full
          : SpeechDetail.terse,
    );
    _announcer = BoardAnnouncer(onValue: (String v) {
      if (mounted) setState(() => _value = v);
    });
    _game.addListener(_onGameChanged);
    _value = _game.cursorSpeech;
    _game.rules = widget.settings.goRules;
    _opponent = _makeOpponent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer.view = View.of(context);
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    unawaited(_tuningSub?.cancel());
    // 앱이 닫힐 때 katago.exe 가 남으면 GPU 메모리를 물고 있다 (K8)
    _opponent?.dispose();
    unawaited(_katago?.stop());
    _announcer.dispose();
    _game.dispose();
    super.dispose();
  }

  /// 커서가 움직이면 value 채널로만 내보낸다 (announce 금지 — 유실된다)
  void _onGameChanged() {
    _announcer.cursor(_game.cursorSpeech);
  }

  /// 결과 종류에 따라 채널을 고른다
  bool _handle(PlayOutcome outcome) {
    switch (outcome) {
      case PlayedMove(:final String speech):
        _announcer.critical(speech);
        setState(() => _status = speech);
        return true;
      case RejectedMove(:final String speech):
        _announcer.critical(speech);
        setState(() => _status = speech);
        return false;
      case GameEnded(:final String speech):
        _announcer.critical(speech);
        setState(() => _status = speech);
        return true;
      case SpokeOnly(:final String speech):
        if (speech.isEmpty) return false;
        _announcer.critical(speech);
        setState(() => _status = speech);
        return true;
    }
  }

  /// 설정과 이 기기의 능력에 맞는 상대를 만든다.
  ///
  /// KataGo 는 데스크톱에서만 돌아가고(모바일에 Process 가 없다), 죽으면
  /// 내장 AI 로 이어 둔다. 어느 경우든 대국이 멈추지는 않는다.
  Opponent? _makeOpponent() {
    final AppSettings st = widget.settings;
    if (st.opponent == OpponentKind.none) return null;

    final BuiltinOpponent builtin = BuiltinOpponent(st.rankId);
    if (st.opponent != OpponentKind.katago) return builtin;
    if (!widget.caps.canRunKataGo) {
      // 설정에는 KataGo 로 되어 있지만 이 기기에서는 안 된다.
      // 조용히 바꾸지 않고 한 번 알린다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _announcer.critical(S.katagoMobileUnavailable(_lang));
      });
      return builtin;
    }

    final KataGoProcess proc = KataGoProcess();
    _katago = proc;
    // OpenCL 최초 튜닝은 몇 분 걸린다. 진행을 보여주지 않으면 멈춘 것처럼
    // 보이고, 그게 K3 이 요구하는 것이다.
    _tuningSub = proc.stderrLog.listen((String line) {
      if (mounted && line.toLowerCase().contains('tuning')) {
        setState(() => _status = S.katagoTuning(_lang));
      }
    });
    unawaited(_startKataGo(proc, st));

    return FallbackOpponent(
      primary: KataGoOpponent(proc, st.rankId),
      backup: builtin,
      onFallback: (String key, String? detail) {
        if (!mounted) return;
        final String msg = allStrings[key]?.call(_lang) ?? key;
        _announcer.critical(msg);
        setState(() => _status = msg);
      },
    );
  }

  Future<void> _startKataGo(KataGoProcess proc, AppSettings st) async {
    try {
      await proc.start(KataGoPaths.resolve(
        root: st.katagoExe.isEmpty ? '.' : st.katagoExe,
        exeOverride: st.katagoExe.isEmpty ? null : st.katagoExe,
        modelOverride: st.katagoModel.isEmpty ? null : st.katagoModel,
        configOverride: st.katagoConfig.isEmpty ? null : st.katagoConfig,
      ));
    } on KataGoException catch (e) {
      // 여기서 실패해도 첫 착수에서 FallbackOpponent 가 내장 AI 로 넘긴다.
      // 다만 이유는 지금 알려 준다 — 나중에 알면 원인을 못 잇는다.
      if (!mounted) return;
      final String msg =
          allStrings[kataGoErrorKey(e.error)]?.call(_lang) ?? e.error.name;
      _announcer.critical(msg);
      setState(() => _status = msg);
    }
  }

  /// 사람이 둔 뒤 상대에게 차례를 넘긴다.
  ///
  /// 상대 수는 포커스가 어디에 있든 낭독돼야 한다(체크리스트 A7).
  /// _handle 이 critical 채널로 보내므로 좌표 입력칸에 있어도 들린다.
  Future<void> _letOpponentPlay() async {
    final Opponent? engine = _opponent;
    if (engine == null || _game.state.ended) return;
    if (_game.state.toPlay == _humanSide) return;

    setState(() => _thinking = true);
    try {
      final OpponentReply reply = await engine.nextMove(_game.state);
      if (!mounted) return;
      switch (reply) {
        case OpponentMove(:final Point point):
          _handle(_game.applyOpponent(point.x, point.y));
        case OpponentPass():
          _handle(_game.pass());
        case OpponentFailed(:final String reasonKey, :final String? detail):
          // 조용히 멈추지 않는다 — 차례가 왜 안 넘어오는지 말해 준다
          final String msg = allStrings[reasonKey]?.call(_lang) ?? reasonKey;
          _announcer.critical(detail == null ? msg : '$msg ($detail)');
          setState(() => _status = msg);
      }
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  /// 사람 착수 처리 + 상대 응수.
  ///
  /// 반환값은 좌표 입력칸이 쓴다 — 성공이면 비우고, 실패면 텍스트를
  /// 선택 상태로 남겨 고쳐 칠 수 있게 한다(체크리스트 A11·A12).
  bool _handleAndReply(PlayOutcome outcome) {
    // 판이 바뀌면 계가 표시는 더 이상 맞지 않는다
    if (_score != null) setState(() => _score = null);
    final bool ok = _handle(outcome);
    if (ok && _vsEngine) unawaited(_letOpponentPlay());
    return ok;
  }

  void _onIntent(BoardIntent intent) {
    switch (intent) {
      case BoardIntent.arm:
        if (widget.settings.placeMode == PlaceMode.confirm) {
          _game.arm();
          _announcer.critical('${_game.cursorLabel} ${S.selectedPoint(_lang)}');
        } else {
          _announcer.flush();
          _handleAndReply(_game.placeAtCursor());
        }
      case BoardIntent.place:
        _announcer.flush();
        if (widget.settings.placeMode == PlaceMode.confirm && !_game.armed) {
          _game.arm();
          _announcer.critical('${_game.cursorLabel} ${S.selectedPoint(_lang)}');
        } else {
          _handleAndReply(_game.placeAtCursor());
        }
      case BoardIntent.disarm:
        _game.disarm();
      case BoardIntent.help:
        _handle(_game.submitInput('?'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final BoardPalette palette = BoardPalette.byId(widget.settings.palette);
    final VisionSettings v = widget.vision;
    // AI 가 생각하는 동안은 사람 착수를 막는다. 두 수가 겹치면 판이 어긋난다.
    final bool interactive = !_game.state.ended && !_thinking;

    return Scaffold(
      appBar: AppBar(title: Text(S.solo(_lang))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            // 좁거나 글자가 크면 세로로 쌓는다 — Flutter 는 CSS 처럼
            // reflow 하지 않으므로 명시적으로 다뤄야 넘침이 안 난다
            final bool stack = c.maxWidth < 900 || v.baseFontSize >= 26;
            final Widget board = _buildBoard(palette, v, interactive);
            final Widget side = _buildSide(v, interactive);
            return stack
                ? SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: c.maxHeight * 0.55, child: board),
                        const SizedBox(height: 12),
                        side,
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: board),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 340,
                        child: SingleChildScrollView(child: side),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildBoard(BoardPalette palette, VisionSettings v, bool interactive) {
    return BoardView(
      key: _boardKey,
      state: _game.state,
      cursor: _game.cursor,
      armed: _game.armed,
      lastMove: _game.lastMove,
      palette: palette,
      vision: v,
      semanticsLabel: '${_game.lines}${S.rowSuffix(_lang)} ${S.boardLabel(_lang)}',
      semanticsValue: _value,
      semanticsHint: S.boardHint(_lang),
      interactive: interactive,
      coordMode: switch (widget.settings.coordMode) {
        CoordMode.auto => CoordDisplayMode.auto,
        CoordMode.on => CoordDisplayMode.on,
        CoordMode.off => CoordDisplayMode.off,
      },
      lineWidth: switch (widget.settings.lineWeight) {
        LineWeight.thin => 1.5,
        LineWeight.normal => 2.5,
        LineWeight.thick => 4,
      },
      ownership: _score?.ownership,
      onMoveCursor: _game.moveCursor,
      onSetCursor: _game.setCursor,
      onIntent: _onIntent,
    );
  }

  Widget _buildSide(VisionSettings v, bool interactive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CursorReadout(text: _value, vision: v, status: _status),
        const SizedBox(height: 12),
        CoordField(
          key: _coordKey,
          label: S.coordInputLabel(_lang),
          hint: S.coordInputHint(_lang),
          helper: S.coordInputHelper(_lang),
          vision: v,
          enabled: interactive,
          onSubmit: (String raw) => _handleAndReply(
              _game.submitInput(raw, lastSpoken: _announcer.lastSpoken)),
        ),
        const SizedBox(height: 12),
        if (interactive && widget.settings.placeMode == PlaceMode.confirm)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton(
              // 19줄에서 교차점을 50px 로 만드는 건 불가능하므로
              // 실제로 커밋하는 타깃을 크게 만든다
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kListItemMin),
              ),
              onPressed: _game.armed && !_game.cursorOccupied
                  ? () => _handleAndReply(_game.placeAtCursor())
                  : null,
              child: Text('${S.confirmPlace(_lang)} (${_game.cursorLabel})'),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _action(S.pass(_lang), interactive,
                () => _handleAndReply(_game.pass())),
            _action(S.askHint(_lang), interactive, () => _handle(_game.hint())),
            // 무를 것이 없으면 눌러도 아무 일이 없는 대신 비활성으로 알린다
            _action(S.undoMove(_lang), interactive && _game.canUndo,
                () => _handle(_game.undo(plies: _vsEngine ? 2 : 1))),
            _action(
              _score == null ? S.scoreNow(_lang) : S.offLabel(_lang),
              true,
              () {
                if (_score != null) {
                  setState(() => _score = null);
                  return;
                }
                setState(() => _score = _game.currentScore());
                _handle(_game.scoreGame());
              },
            ),
            _action(S.resign(_lang), interactive,
                () => _handle(_game.resignGame(_game.state.toPlay))),
          ],
        ),
      ],
    );
  }

  Widget _action(String label, bool enabled, VoidCallback onTap) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kTouchLarge, kTouchLarge),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(label),
      );
}
