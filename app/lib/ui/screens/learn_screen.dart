// lib/ui/screens/learn_screen.dart — 배우기
//
// 대국 화면과 같은 판·낭독 모델을 쓴다. 판을 다루는 법이 화면마다
// 다르면 스크린리더 사용자가 두 번 배워야 한다.

import 'package:flutter/material.dart';

import '../../application/learn_controller.dart';
import '../../data/db/settings_store.dart';
import '../../domain/engine/types.dart';
import '../../domain/input/board_speech.dart';
import '../../domain/learn/curriculum.dart';
import '../../i18n/strings.g.dart';
import '../theme/board_theme.dart';
import '../theme/svil_theme.dart';
import '../widgets/board/board_announcer.dart';
import '../widgets/board/board_view.dart';
import '../widgets/board/cursor_readout.dart';
import 'solo_screen.dart' show speechFor;

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    required this.curriculum,
    required this.settings,
    required this.vision,
    required this.solved,
    required this.onProgress,
    super.key,
  });

  final Curriculum curriculum;
  final AppSettings settings;
  final VisionSettings vision;
  final Set<String> solved;

  /// 문제를 풀 때마다 저장한다 — 앱이 죽어도 진행이 남아야 한다
  final void Function(Set<String> solved) onProgress;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final LearnController _learn;
  late final BoardAnnouncer _announcer;
  final GlobalKey<BoardViewState> _boardKey = GlobalKey<BoardViewState>();

  String _value = '';
  String _status = '';

  Lang get _lang => widget.settings.lang;

  @override
  void initState() {
    super.initState();
    _learn = LearnController(
      curriculum: widget.curriculum,
      solved: widget.solved,
      speech: speechFor(_lang),
      detail: widget.settings.verbosity == AnnounceVerbosity.full
          ? SpeechDetail.full
          : SpeechDetail.terse,
    );
    _announcer = BoardAnnouncer(onValue: (String v) {
      if (mounted) setState(() => _value = v);
    });
    _learn.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer.view = View.of(context);
  }

  @override
  void dispose() {
    _learn.removeListener(_onChanged);
    _announcer.dispose();
    _learn.dispose();
    super.dispose();
  }

  void _onChanged() => _announcer.cursor(_learn.cursorSpeech);

  void _say(String text) {
    _announcer.critical(text);
    setState(() => _status = text);
  }

  void _attempt() {
    _announcer.flush();
    final AttemptOutcome r = _learn.attemptAtCursor();
    switch (r) {
      case AttemptCorrect(:final bool stageCleared, :final bool trackCleared):
        widget.onProgress(_learn.solvedIds);
        final List<String> parts = <String>[
          '${_learn.cursorLabel}, ${S.learnCorrect(_lang)}',
          if (stageCleared) S.learnStageCleared(_lang),
          if (trackCleared) S.learnTrackCleared(_lang),
        ];
        _say(parts.join('. '));
      case AttemptWrong(:final String reasonKey, :final String? detail):
        final String why = allStrings[reasonKey]?.call(_lang) ?? reasonKey;
        // 좌표를 앞에 둔다 — 발화가 끊겨도 어디를 눌렀는지는 전달된다
        _say('${_learn.cursorLabel}, $why${detail == null ? '' : ' ($detail)'}'
            '${_learn.misses >= 2 ? '. ${S.learnTryHint(_lang)}' : ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_learn.stage == null) return _buildStageList();
    return _buildProblem();
  }

  Widget _buildStageList() {
    return Scaffold(
      appBar: AppBar(title: Text(S.learn(_lang))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final LearnTrack track in LearnTrack.values) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _trackName(track),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final LearnStage s in widget.curriculum.forTrack(track))
              _stageTile(s),
          ],
        ],
      ),
    );
  }

  Widget _stageTile(LearnStage s) {
    final bool unlocked = _learn.isUnlocked(s);
    final bool cleared = _learn.stageCleared(s);
    final int done =
        s.problems.where((LearnProblem p) => _learn.isSolved(p.id)).length;

    // 잠김·완료를 색이 아니라 글로도 알린다
    final String state = cleared
        ? S.learnStageCleared(_lang)
        : unlocked
            ? '$done / ${s.problems.length}'
            : S.learnLocked(_lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        enabled: unlocked,
        label: '${s.title(_lang.code)}, $state',
        child: ExcludeSemantics(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(kListItemMin),
              alignment: Alignment.centerLeft,
            ),
            onPressed: unlocked ? () => _learn.openStage(s) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(s.title(_lang.code)),
                Text(state, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _trackName(LearnTrack t) => switch (t) {
        LearnTrack.basics => S.learnTrackBasics(_lang),
        LearnTrack.fuseki => S.learnTrackFuseki(_lang),
        LearnTrack.tsumego => S.learnTrackTsumego(_lang),
      };

  Widget _buildProblem() {
    final LearnProblem? p = _learn.problem;
    final GameState? board = _learn.board;
    if (p == null || board == null) return _buildStageList();

    final BoardPalette palette = BoardPalette.byId(widget.settings.palette);
    final VisionSettings v = widget.vision;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_learn.stage!.title(_lang.code)} '
            '${_learn.position}/${_learn.total}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: S.learn(_lang),
          onPressed: _learn.closeStage,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget boardWidget =
                _buildBoard(board, palette, v);
            final Widget side = _buildSide(p, v);
            // 대국 화면과 같은 기준으로 세로 전환한다
            final bool stack = c.maxWidth < 900 || v.baseFontSize >= 26;
            return stack
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // 스크롤 안에서는 높이가 무한이라 판이 크기를 못 정한다.
                        // 대국 화면과 같은 비율로 명시한다.
                        SizedBox(height: c.maxHeight * 0.55, child: boardWidget),
                        const SizedBox(height: 16),
                        side,
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: boardWidget),
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

  Widget _buildBoard(GameState board, BoardPalette palette, VisionSettings v) =>
      BoardView(
        key: _boardKey,
        state: board,
        cursor: _learn.cursor,
        armed: false,
        lastMove: null,
        palette: palette,
        vision: v,
        semanticsLabel: '${_learn.lines}${S.rowSuffix(_lang)} '
            '${S.boardLabel(_lang)}, ${_learn.problem!.goalLabel(_lang.code)}',
        semanticsValue: _value,
        semanticsHint: S.boardHint(_lang),
        interactive: true,
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
        onMoveCursor: _learn.moveCursor,
        onSetCursor: _learn.setCursor,
        onIntent: (BoardIntent i) {
          switch (i) {
            case BoardIntent.arm:
            case BoardIntent.place:
              _attempt();
            case BoardIntent.disarm:
              break;
            case BoardIntent.help:
              _say(_learn.problem!.hint(_lang.code));
          }
        },
      );

  Widget _buildSide(LearnProblem p, VisionSettings v) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(p.title(_lang.code),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(p.goalLabel(_lang.code)),
          const SizedBox(height: 12),
          CursorReadout(text: _value, vision: v, status: _status),
          const SizedBox(height: 12),
          if (_learn.hintShown) ...<Widget>[
            Text(p.hint(_lang.code)),
            if (p.note != null) Text(p.note!(_lang.code)),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _action(S.askHint(_lang), true, () {
                _learn.showHint();
                _say(p.hint(_lang.code));
              }),
              _action(S.learnShowAnswer(_lang), true, () {
                _learn.revealAnswer();
                _say('${_learn.cursorLabel}, ${S.learnShowAnswer(_lang)}');
              }),
              _action(S.learnRetry(_lang), true, () {
                _learn.retry();
                _say(S.learnRetry(_lang));
              }),
              _action(S.learnPrevProblem(_lang), _learn.hasPrevious,
                  () => _learn.previous()),
              _action(S.learnNextProblem(_lang), _learn.hasNext,
                  () => _learn.next()),
            ],
          ),
        ],
      );

  Widget _action(String label, bool enabled, VoidCallback onTap) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kTouchLarge, kTouchLarge),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(label),
      );
}
