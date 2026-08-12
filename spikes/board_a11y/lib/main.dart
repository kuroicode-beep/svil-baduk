// spikes/board_a11y — Flutter Windows 접근성 스파이크
//
// 목적: 격자 시맨틱스 없이 바둑판을 스크린리더로 조작할 수 있는지 NVDA·JAWS 로 실측.
// 엔진·i18n·저장 없음. 통과 기준은 docs/reports/ 의 스파이크 보고서 참조.
//
// 검증하려는 구조:
//   판 안에 포커스 노드는 정확히 1개 (361개 아님)
//   커서 위치는 그 노드의 Semantics.value 로 전달  ← MSAA VALUECHANGE
//   사건·오류만 SemanticsService.announce
//   좌표 텍스트 입력이 동등한 1급 경로

import 'dart:async';
import 'dart:ui' show AccessibilityFeatures, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'announcer.dart';
import 'board_painter.dart';
import 'coord.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _printAccessibilityDiagnostics();
  PlatformDispatcher.instance.onAccessibilityFeaturesChanged =
      _printAccessibilityDiagnostics;
  runApp(const SpikeApp());
}

/// 스크린리더 없이도 얻을 수 있는 실측 데이터 — 보고서에 그대로 붙인다.
/// 스크린리더를 켜고 끄면 onAccessibilityFeaturesChanged 로 다시 찍힌다.
void _printAccessibilityDiagnostics() {
  final AccessibilityFeatures f = PlatformDispatcher.instance.accessibilityFeatures;
  debugPrint('=== A11Y DIAGNOSTICS ===');
  debugPrint('accessibleNavigation : ${f.accessibleNavigation}   <- 스크린리더 실행 중이면 true');
  debugPrint('supportsAnnounce     : ${f.supportsAnnounce}       <- announce 가 먹히는 플랫폼인가');
  debugPrint('highContrast         : ${f.highContrast}           <- Windows 에서는 항상 false 예상');
  debugPrint('disableAnimations    : ${f.disableAnimations}');
  debugPrint('boldText             : ${f.boldText}               <- Windows 에서는 항상 false 예상');
  debugPrint('invertColors         : ${f.invertColors}');
  debugPrint('semanticsEnabled     : ${WidgetsBinding.instance.semanticsEnabled}');
  debugPrint('========================');
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVIL Baduk — 접근성 스파이크',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF16161D),
          primary: Color(0xFF7EC8FF),
        ),
        textTheme: const TextTheme().apply(bodyColor: const Color(0xFFF5F5F7)),
      ),
      home: const SpikeScreen(),
    );
  }
}

const int kSize = 19;

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final FocusNode _boardFocus = FocusNode(debugLabel: 'board');
  final FocusNode _coordFocus = FocusNode(debugLabel: 'coord');
  final TextEditingController _coordCtrl = TextEditingController();

  late final BoardAnnouncer _announcer;

  List<int> _stones = List<int>.filled(kSize * kSize, 0);
  ({int x, int y}) _cursor = (x: 9, y: 9);
  ({int x, int y})? _lastMove;
  bool _armed = false;
  String _value = '';
  String _readout = '';
  String _status = '';
  Timer? _opponentTimer;
  int _moveCount = 0;
  bool _supportsAnnounce = false;

  @override
  void initState() {
    super.initState();
    _announcer = BoardAnnouncer(onValue: (String v) {
      if (!mounted) return;
      setState(() {
        _value = v;
        _readout = v;
      });
    });
    _readout = _describe(_cursor.x, _cursor.y);
    _value = _readout;
  }

  @override
  void dispose() {
    _opponentTimer?.cancel();
    _announcer.dispose();
    _boardFocus.dispose();
    _coordFocus.dispose();
    _coordCtrl.dispose();
    super.dispose();
  }

  int _at(int x, int y) => _stones[y * kSize + x];

  /// 좌표가 항상 문장 맨 앞 — 발화가 끊겨도 위치는 전달된다
  String _describe(int x, int y) {
    final String coord = pointLabel(x, y, kSize);
    final int s = _at(x, y);
    final String who = s == 0 ? '빈 점' : (s == 1 ? '흑' : '백');
    final bool star = _isStar(x, y);
    final bool isLast = _lastMove?.x == x && _lastMove?.y == y;
    return <String>[
      coord,
      who,
      if (star) '화점',
      if (isLast) '직전 수',
    ].join(', ');
  }

  bool _isStar(int x, int y) {
    const List<int> c = <int>[3, 9, 15];
    return c.contains(x) && c.contains(y);
  }

  void _moveCursor(int dx, int dy) {
    setState(() {
      _cursor = (
        x: (_cursor.x + dx).clamp(0, kSize - 1),
        y: (_cursor.y + dy).clamp(0, kSize - 1),
      );
      _armed = false;
    });
    _announcer.cursor(_describe(_cursor.x, _cursor.y));
  }

  void _place(int x, int y) {
    _announcer.flush();
    if (_at(x, y) != 0) {
      _announcer.critical(
          '${pointLabel(x, y, kSize)} 둘 수 없음: 이미 돌이 있습니다');
      setState(() => _status = '반칙 — 이미 돌이 있습니다');
      return;
    }
    setState(() {
      _stones = List<int>.from(_stones)..[y * kSize + x] = 1;
      _lastMove = (x: x, y: y);
      _cursor = (x: x, y: y);
      _armed = false;
      _moveCount++;
      _status = '착수 ${pointLabel(x, y, kSize)}';
    });
    _announcer.critical('흑 ${pointLabel(x, y, kSize)}, 백 차례');
    _scheduleOpponent();
  }

  /// 상대 착수를 3초 뒤에 — 포커스가 좌표 필드에 있어도 들리는지 시험
  void _scheduleOpponent() {
    _opponentTimer?.cancel();
    _opponentTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      int ox = 0, oy = 0;
      for (int i = 0; i < kSize * kSize; i++) {
        final int idx = (i * 37 + _moveCount * 11) % (kSize * kSize);
        if (_stones[idx] == 0) {
          ox = idx % kSize;
          oy = idx ~/ kSize;
          break;
        }
      }
      setState(() {
        _stones = List<int>.from(_stones)..[oy * kSize + ox] = 2;
        _lastMove = (x: ox, y: oy);
        _status = '상대 ${pointLabel(ox, oy, kSize)}';
      });
      _announcer.event('백 ${pointLabel(ox, oy, kSize)}, 흑 차례');
    });
  }

  void _submitCoord(String raw) {
    final ParsedInput parsed = parseInput(raw, kSize);
    switch (parsed) {
      case ParsedPoint(:final int x, :final int y):
        setState(() => _cursor = (x: x, y: y));
        _place(x, y);
        _coordCtrl.clear();
        _coordFocus.requestFocus();
      case ParsedCommand(:final Command command):
        _runCommand(command);
        _coordCtrl.clear();
        _coordFocus.requestFocus();
      case ParsedQuery(x: final int? qx, y: final int? qy, row: final int? row):
        if (qx != null && qy != null) {
          _announcer.critical(_describe(qx, qy));
        } else if (row != null) {
          _announcer.critical(_readRow(row));
        }
        _coordCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: _coordCtrl.text.length);
      case ParsedError():
        _announcer.critical(describeError(parsed, kSize));
        setState(() => _status = describeError(parsed, kSize));
        // 실패 시 텍스트는 선택 상태로 남긴다 — 고쳐 쓰기 쉽게
        _coordCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: _coordCtrl.text.length);
    }
  }

  String _readRow(int row) {
    final int y = kSize - row;
    final List<String> parts = <String>[];
    for (int x = 0; x < kSize; x++) {
      final int s = _at(x, y);
      if (s != 0) parts.add('${columnLabel(x)} ${s == 1 ? '흑' : '백'}');
    }
    return parts.isEmpty ? '$row 줄, 돌 없음' : '$row 줄, ${parts.join(', ')}';
  }

  String _summary() {
    int black = 0, white = 0;
    for (final int s in _stones) {
      if (s == 1) black++;
      if (s == 2) white++;
    }
    return '$kSize 줄 판, 흑 $black 점, 백 $white 점, '
        '${_lastMove == null ? '직전 수 없음' : '직전 수 ${pointLabel(_lastMove!.x, _lastMove!.y, kSize)}'}';
  }

  void _runCommand(Command c) {
    switch (c) {
      case Command.summary:
        _announcer.critical(_summary());
      case Command.repeat:
        _announcer.critical(_readout);
      case Command.help:
        _announcer.critical(
            '화살표로 이동, 엔터로 착수, Ctrl L 좌표 입력, 물음표로 판 요약');
      case Command.pass:
        _announcer.critical('흑 패스, 백 차례');
        _scheduleOpponent();
      case Command.resign:
        _announcer.critical('흑 기권, 백 승');
      case Command.undo:
      case Command.score:
      case Command.hint:
        _announcer.critical('스파이크에서는 지원하지 않습니다');
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final bool ctrl = HardwareKeyboard.instance.isControlPressed;
    final LogicalKeyboardKey k = event.logicalKey;

    if (ctrl && k == LogicalKeyboardKey.keyL) {
      _coordFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight) return _handled(() => _moveCursor(1, 0));
    if (k == LogicalKeyboardKey.arrowLeft) return _handled(() => _moveCursor(-1, 0));
    if (k == LogicalKeyboardKey.arrowDown) return _handled(() => _moveCursor(0, 1));
    if (k == LogicalKeyboardKey.arrowUp) return _handled(() => _moveCursor(0, -1));
    if (k == LogicalKeyboardKey.pageUp) return _handled(() => _moveCursor(0, -5));
    if (k == LogicalKeyboardKey.pageDown) return _handled(() => _moveCursor(0, 5));
    if (k == LogicalKeyboardKey.home) {
      return _handled(() => setState(() => _cursor = (x: 0, y: _cursor.y)));
    }
    if (k == LogicalKeyboardKey.end) {
      return _handled(() => setState(() => _cursor = (x: kSize - 1, y: _cursor.y)));
    }
    if (k == LogicalKeyboardKey.escape) {
      if (_armed) return _handled(() => setState(() => _armed = false));
      return KeyEventResult.ignored; // 포커스를 가두지 않는다
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
      return _handled(() {
        if (_armed) {
          _place(_cursor.x, _cursor.y);
        } else {
          setState(() => _armed = true);
          _announcer.critical(
              '${pointLabel(_cursor.x, _cursor.y, kSize)} 선택됨. 한 번 더 눌러 착수');
        }
      });
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handled(VoidCallback fn) {
    fn();
    return KeyEventResult.handled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer.view = View.of(context);
    _supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final BoardModel model = BoardModel(
      size: kSize,
      stones: _stones,
      cursor: _cursor,
      armed: _armed,
      lastMove: _lastMove,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('접근성 스파이크 — 19줄')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  // 시각 전용 — 중복 발화가 무발화보다 나쁘다
                  ExcludeSemantics(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F2A),
                        border: Border.all(color: const Color(0xFF6B6B82), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _readout,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Color(0xFFFFFF00),
                          fontFamily: 'Consolas',
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildBoard(model)),
                  const SizedBox(height: 12),
                  _buildCoordField(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 320, child: _buildLog()),
          ],
        ),
      ),
    );
  }

  /// 판 전체에서 포커스 노드는 이것 하나뿐이다
  Widget _buildBoard(BoardModel model) {
    return Semantics(
      focusable: true,
      focused: _boardFocus.hasFocus,
      label: '$kSize 줄 바둑판',
      value: _value,
      hint: '화살표로 이동, 엔터로 착수, 컨트롤 L 로 좌표 입력',
      onTap: () => _place(_cursor.x, _cursor.y),
      child: Focus(
        focusNode: _boardFocus,
        onKeyEvent: _onKey,
        onFocusChange: (_) => setState(() {}),
        child: GestureDetector(
          onTap: () => _boardFocus.requestFocus(),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _boardFocus.hasFocus
                    ? const Color(0xFFFFFF00)
                    : const Color(0xFF6B6B82),
                width: _boardFocus.hasFocus ? 3 : 2,
              ),
            ),
            child: CustomPaint(
              painter: BoardPainter(
                model: model,
                theme: BoardTheme.highContrast,
                showCoords: true,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordField() {
    return TextField(
      controller: _coordCtrl,
      focusNode: _coordFocus,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.go,
      style: const TextStyle(fontSize: 24, fontFamily: 'Consolas'),
      decoration: const InputDecoration(
        labelText: '좌표 입력',
        hintText: '예: D16, 패스, ?',
        helperText: '엔터로 착수. ? 판 요약, ?D16 그 지점, ?16 그 줄',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      onSubmitted: _submitCoord,
    );
  }

  Widget _buildLog() {
    final List<AnnounceRecord> recent = _announcer.log.reversed.take(40).toList();
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('내보낸 안내 ${_announcer.log.length}건',
              style: const TextStyle(fontSize: 18, color: Color(0xFF7EC8FF))),
          Text(
            'supportsAnnounce: $_supportsAnnounce',
            style: TextStyle(
              fontSize: 16,
              color: _supportsAnnounce
                  ? const Color(0xFF7EE2A8)
                  : const Color(0xFFFF9B9B),
            ),
          ),
          Text(_status, style: const TextStyle(fontSize: 16, color: Color(0xFFFFD479))),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: recent.length,
              itemBuilder: (BuildContext c, int i) => Text(
                recent[i].toString(),
                style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
