// lib/ui/screens/solo_screen.dart — 혼자 두기
//
// 접근성 모델의 조립 지점. 판(포커스 노드 1개) + 좌표 입력(1급 경로) +
// 화면상 쌍둥이 readout + 큰 동작 버튼.

import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../data/db/settings_store.dart';
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
    super.key,
  });

  final AppSettings settings;
  final VisionSettings vision;
  final BoardSize size;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer.view = View.of(context);
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
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

  void _onIntent(BoardIntent intent) {
    switch (intent) {
      case BoardIntent.arm:
        if (widget.settings.placeMode == PlaceMode.confirm) {
          _game.arm();
          _announcer.critical('${_game.cursorLabel} ${S.selectedPoint(_lang)}');
        } else {
          _announcer.flush();
          _handle(_game.placeAtCursor());
        }
      case BoardIntent.place:
        _announcer.flush();
        if (widget.settings.placeMode == PlaceMode.confirm && !_game.armed) {
          _game.arm();
          _announcer.critical('${_game.cursorLabel} ${S.selectedPoint(_lang)}');
        } else {
          _handle(_game.placeAtCursor());
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
    final bool interactive = !_game.state.ended;

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
          onSubmit: (String raw) =>
              _handle(_game.submitInput(raw, lastSpoken: _announcer.lastSpoken)),
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
                  ? () => _handle(_game.placeAtCursor())
                  : null,
              child: Text('${S.confirmPlace(_lang)} (${_game.cursorLabel})'),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _action(S.pass(_lang), interactive, () => _handle(_game.pass())),
            _action(S.askHint(_lang), false, () {}),
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
