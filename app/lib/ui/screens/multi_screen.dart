// lib/ui/screens/multi_screen.dart — 상대랑 두기 (P2P)
//
// 로비: 내 방 ID(한 글자씩 낭독·QR·복사) + 상대 방 ID 입력.
// 대국: 솔로와 같은 접근성 모델 — 판(포커스 노드 1개) + 좌표칸 + readout.
// 원격 수·연결 사건은 critical 채널로 낭독된다(포커스 위치 무관, A7).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../application/app_container.dart';
import '../../application/game_controller.dart';
import '../../application/multi_controller.dart';
import '../../data/db/settings_store.dart';
import '../../data/p2p/webrtc_endpoint.dart';
import '../../domain/engine/scoring.dart';
import '../../domain/engine/types.dart';
import '../../domain/input/board_speech.dart';
import '../../domain/input/coord_input.dart';
import '../../domain/p2p/transport.dart';
import '../../i18n/strings.g.dart';
import '../theme/board_theme.dart';
import '../theme/svil_theme.dart';
import '../widgets/board/board_announcer.dart';
import '../widgets/board/board_view.dart';
import '../widgets/board/coord_field.dart';
import '../widgets/board/cursor_readout.dart';
import '../widgets/confirm_resign.dart';
import 'solo_screen.dart' show speechFor, moveErrorPhraseFor, coordErrorPhraseFor;

class MultiScreen extends StatefulWidget {
  const MultiScreen({
    required this.container,
    this.makeEndpoint,
    super.key,
  });

  final AppContainer container;

  /// 테스트가 가짜 전송을 끼운다. null 이면 실제 WebRTC.
  final P2PEndpoint Function()? makeEndpoint;

  @override
  State<MultiScreen> createState() => _MultiScreenState();
}

class _MultiScreenState extends State<MultiScreen> {
  late final MultiController _multi;
  late final BoardAnnouncer _announcer;
  final TextEditingController _peerId = TextEditingController();
  final GlobalKey<CoordFieldState> _coordKey = GlobalKey<CoordFieldState>();

  String _value = '';
  String _status = '';
  ScoreBreakdown? _score;

  Lang get _lang => widget.container.settings.settings.lang;
  AppSettings get _st => widget.container.settings.settings;

  @override
  void initState() {
    super.initState();
    _announcer = BoardAnnouncer(onValue: (String v) {
      if (mounted) setState(() => _value = v);
    });
    _multi = MultiController(
      endpoint: widget.makeEndpoint?.call() ?? WebRtcEndpoint(),
      makeGame: (BoardSize size) => GameController(
        size: size,
        speech: speechFor(_lang),
        moveErrorPhrase: (MoveError e) => moveErrorPhraseFor(_lang, e),
        coordErrorPhrase: (CoordError e, int lines) =>
            coordErrorPhraseFor(_lang, e, lines),
        detail: _st.verbosity == AnnounceVerbosity.full
            ? SpeechDetail.full
            : SpeechDetail.terse,
      )..rules = _st.goRules,
      onSession: _onSession,
    );
    _multi.size = _st.boardSize;
    _multi.addListener(_onMultiChanged);
    _value = _multi.game.cursorSpeech;
    unawaited(_multi.openRoom());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer.view = View.of(context);
  }

  @override
  void dispose() {
    _multi.removeListener(_onMultiChanged);
    _multi.dispose();
    _peerId.dispose();
    _announcer.dispose();
    super.dispose();
  }

  void _onMultiChanged() {
    _announcer.cursor(_multi.game.cursorSpeech);
  }

  /// 세션 사건 → 낭독. 원격 수는 GameController 가 만든 문장을 그대로 쓴다.
  void _onSession(MultiSessionEvent e) {
    if (!mounted) return;
    switch (e) {
      case MultiStarted():
        final String color =
            _multi.myColor == Stone.black ? S.black(_lang) : S.white(_lang);
        _say('${S.connected(_lang)} — ${S.playAs(_lang)}: $color');
      case MultiRemoteOutcome(:final PlayOutcome outcome):
        if (_score != null) setState(() => _score = null);
        _handle(outcome);
      case MultiTrouble(:final String reasonKey, :final String? detail):
        final String msg = allStrings[reasonKey]?.call(_lang) ?? reasonKey;
        _say(detail == null ? msg : '$msg ($detail)');
    }
  }

  void _say(String msg) {
    _announcer.critical(msg);
    setState(() => _status = msg);
  }

  bool _handle(PlayOutcome outcome) {
    switch (outcome) {
      case PlayedMove(:final String speech) ||
            GameEnded(:final String speech) ||
            SpokeOnly(:final String speech):
        if (speech.isEmpty) return false;
        _say(speech);
        return true;
      case RejectedMove(:final String speech) ||
            InputError(:final String speech):
        _say(speech);
        return false;
    }
  }

  bool _submit(String raw) {
    if (_multi.isResignCommand(raw)) {
      unawaited(_askResign());
      return true;
    }
    if (_score != null) setState(() => _score = null);
    return _handle(_multi.submitInput(
      raw,
      lastSpoken: _announcer.lastSpoken,
      notYourTurnPhrase: S.notYourTurn(_lang),
      notAvailablePhrase: S.multiNoUndo(_lang),
    ));
  }

  Future<void> _askResign() async {
    if (!await confirmResign(context, _lang)) return;
    if (!mounted) return;
    _handle(_multi.resignMine());
  }

  void _onIntent(BoardIntent intent) {
    if (!_multi.myTurn) {
      if (intent == BoardIntent.arm || intent == BoardIntent.place) {
        _say(S.notYourTurn(_lang));
      }
      return;
    }
    switch (intent) {
      case BoardIntent.arm || BoardIntent.place:
        _announcer.flush();
        if (_st.placeMode == PlaceMode.confirm && !_multi.game.armed) {
          _multi.game.arm();
          _announcer
              .critical('${_multi.game.cursorLabel} ${S.selectedPoint(_lang)}');
        } else {
          if (_score != null) setState(() => _score = null);
          _handle(_multi.placeAtCursor());
        }
      case BoardIntent.disarm:
        _multi.game.disarm();
      case BoardIntent.help:
        _handle(_multi.game.submitInput('?'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _multi,
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(title: Text(S.multi(_lang))),
        body: _multi.phase == MultiScreenPhase.play
            ? _buildPlay(context)
            : _buildLobby(context),
      ),
    );
  }

  // ── 로비 ─────────────────────────────────────────────────

  Widget _buildLobby(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final bool connecting = _multi.phase == MultiScreenPhase.connecting;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(S.p2pHint(_lang), style: t.bodyMedium),
        Text(S.crossPlayNote(_lang), style: t.bodyMedium),
        const SizedBox(height: 16),
        if (_multi.errorKey.isNotEmpty) ...<Widget>[
          Text(
            allStrings[_multi.errorKey]?.call(_lang) ?? _multi.errorKey,
            style: t.bodyLarge,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => unawaited(_multi.openRoom()),
            child: Text(S.reinitPeer(_lang)),
          ),
          const SizedBox(height: 16),
        ],

        // 내 방 ID — 한 글자씩 낭독(P6). 시각으로는 큰 모노스페이스.
        Text(S.yourId(_lang), style: t.titleMedium),
        const SizedBox(height: 8),
        Semantics(
          label: _multi.myId.isEmpty
              ? S.waiting(_lang)
              : _multi.myId.split('').join(', '),
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outline, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _multi.myId.isEmpty ? '…' : _multi.myId,
                style: monoStyle(size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              onPressed: _multi.myId.isEmpty
                  ? null
                  : () {
                      unawaited(Clipboard.setData(
                          ClipboardData(text: _multi.myId)));
                      _say(S.idCopied(_lang));
                    },
              label: Text(S.copyId(_lang)),
            ),
          ],
        ),
        if (_multi.myId.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            label: S.roomQrLabel(_lang),
            child: ExcludeSemantics(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: _multi.myId, size: 168),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // 호스트 설정 — 게스트가 들어오면 이 값으로 시작한다
        Text('${S.boardSize(_lang)} (${S.hostLabel(_lang)})',
            style: t.titleMedium),
        for (final BoardSize b in BoardSize.values)
          RadioListTile<BoardSize>(
            title: Text('${b.lines}${S.rowSuffix(_lang)}'),
            value: b,
            // ignore: deprecated_member_use
            groupValue: _multi.size,
            // ignore: deprecated_member_use
            onChanged: (BoardSize? v) {
              if (v != null) setState(() => _multi.size = v);
            },
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.comfortable,
          ),
        const SizedBox(height: 8),
        Text('${S.playAs(_lang)} (${S.hostLabel(_lang)})',
            style: t.titleMedium),
        for (final (Player, String) o in <(Player, String)>[
          (Stone.black, S.black(_lang)),
          (Stone.white, S.white(_lang)),
        ])
          RadioListTile<Player>(
            title: Text(o.$2),
            value: o.$1,
            // ignore: deprecated_member_use
            groupValue: _multi.hostColor,
            // ignore: deprecated_member_use
            onChanged: (Player? v) {
              if (v != null) setState(() => _multi.hostColor = v);
            },
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.comfortable,
          ),
        const SizedBox(height: 24),

        // 게스트 경로 — 상대 방으로 들어가기
        Text(S.peerId(_lang), style: t.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _peerId,
          style: monoStyle(size: 22),
          decoration: InputDecoration(
            hintText: 'svb-______',
            constraints: const BoxConstraints(minHeight: kTouchLarge),
          ),
          onSubmitted: (_) => unawaited(_join()),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kListItemMin)),
          onPressed: connecting || !_multi.brokerReady
              ? null
              : () => unawaited(_join()),
          child: Text(connecting ? S.waiting(_lang) : S.joinRoom(_lang)),
        ),
        const SizedBox(height: 16),
        CursorReadout(
          text: _multi.brokerReady ? S.waiting(_lang) : '…',
          vision: widget.container.vision.vision,
          status: _status,
        ),
      ],
    );
  }

  Future<void> _join() => _multi.join(_peerId.text);

  // ── 대국 ─────────────────────────────────────────────────

  Widget _buildPlay(BuildContext context) {
    final BoardPalette palette = BoardPalette.byId(_st.palette);
    final VisionSettings v = widget.container.vision.vision;
    final bool interactive = _multi.myTurn;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
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
    );
  }

  Widget _buildBoard(BoardPalette palette, VisionSettings v, bool interactive) {
    return BoardView(
      state: _multi.game.state,
      cursor: _multi.game.cursor,
      armed: _multi.game.armed,
      lastMove: _multi.game.lastMove,
      palette: palette,
      vision: v,
      semanticsLabel:
          '${_multi.game.lines}${S.rowSuffix(_lang)} ${S.boardLabel(_lang)}',
      semanticsValue: _value,
      semanticsHint: S.boardHint(_lang),
      interactive: interactive,
      coordMode: switch (_st.coordMode) {
        CoordMode.auto => CoordDisplayMode.auto,
        CoordMode.on => CoordDisplayMode.on,
        CoordMode.off => CoordDisplayMode.off,
      },
      lineWidth: switch (_st.lineWeight) {
        LineWeight.thin => 1.5,
        LineWeight.normal => 2.5,
        LineWeight.thick => 4,
      },
      ownership: _score?.ownership,
      onFirstFocus: () => _announcer.critical(S.boardHint(_lang)),
      onMoveCursor: _multi.game.moveCursor,
      onSetCursor: _multi.game.setCursor,
      onIntent: _onIntent,
    );
  }

  Widget _buildSide(VisionSettings v, bool interactive) {
    final String turnLine = _multi.game.state.ended
        ? S.gameOver(_lang)
        : !_multi.connected
            ? (allStrings['disconnected']?.call(_lang) ?? '')
            : _multi.myTurn
                ? S.yourTurn(_lang)
                : S.opponentTurn(_lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(turnLine, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        CursorReadout(text: _value, vision: v, status: _status),
        const SizedBox(height: 12),
        CoordField(
          key: _coordKey,
          label: S.coordInputLabel(_lang),
          hint: S.coordInputHint(_lang),
          helper: S.coordInputHelper(_lang),
          vision: v,
          enabled: _multi.connected && !_multi.game.state.ended,
          onSubmit: _submit,
        ),
        const SizedBox(height: 12),
        if (interactive && _st.placeMode == PlaceMode.confirm)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kListItemMin),
              ),
              onPressed: _multi.game.armed && !_multi.game.cursorOccupied
                  ? () => _handle(_multi.placeAtCursor())
                  : null,
              child: Text(
                  '${S.confirmPlace(_lang)} (${_multi.game.cursorLabel})'),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _action(S.pass(_lang), interactive, () {
              if (_score != null) setState(() => _score = null);
              _handle(_multi.passTurn());
            }),
            _action(
              _score == null ? S.scoreNow(_lang) : S.offLabel(_lang),
              true,
              () {
                if (_score != null) {
                  setState(() => _score = null);
                  return;
                }
                setState(() => _score = _multi.game.currentScore());
                _handle(_multi.game.scoreGame());
              },
            ),
            _action(S.resign(_lang), !_multi.game.state.ended,
                () => unawaited(_askResign())),
            _action(S.returnLobby(_lang), true, () {
              setState(() => _score = null);
              unawaited(_multi.leaveGame());
            }),
          ],
        ),
      ],
    );
  }

  Widget _action(String label, bool enabled, VoidCallback onTap) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kTouchLarge, kTouchLarge),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(label),
      );
}
