// lib/data/platform/katago_process.dart — KataGo GTP 직결
//
// React 판은 Node HTTP 브리지(scripts/katago-bridge.mjs, 212줄)를 거쳤다.
// 데스크톱에서는 프로세스를 직접 띄울 수 있으므로 HTTP·CORS·포트 17419·
// PowerShell 런처 4개가 통째로 사라진다.
//
// 브리지에서 반드시 가져와야 하는 것들:
//  · 빈 줄 기준 GTP 프레이밍
//  · FIFO 요청/응답 짝짓기 (GTP 는 순차라 id 태그가 없다)
//  · 모델·설정 자동 탐색
//  · 오류 분류 8종 (UI 가 사유별로 다른 문장을 낭독한다)
//  · stderr 통과 — OpenCL 최초 튜닝 진행이 여기 나온다. 수 분 걸릴 수 있어
//    UI 에 노출하지 않으면 사용자에게는 멈춘 것으로 보인다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum KataGoError {
  exeMissing,
  modelMissing,
  configMissing,
  notRunning,
  exited,
  emptyResponse,
  rejected,
  timeout,
  startFailed,
}

class KataGoException implements Exception {
  const KataGoException(this.error, [this.detail = '']);
  final KataGoError error;
  final String detail;

  @override
  String toString() => 'KataGoException(${error.name}${detail.isEmpty ? '' : ': $detail'})';
}

/// 대기 중인 요청 하나
class _Pending {
  _Pending(this.command, this.completer);
  final String command;
  final Completer<String> completer;
}

/// 실행 파일·모델·설정 경로를 찾는다 (브리지의 자동 탐색을 옮긴 것)
class KataGoPaths {
  const KataGoPaths({required this.exe, required this.model, required this.config});
  final String exe;
  final String model;
  final String config;

  /// katago/ 폴더 규약대로 찾는다. 못 찾으면 어느 것이 없는지 알려준다.
  static KataGoPaths resolve({
    required String root,
    String? exeOverride,
    String? modelOverride,
    String? configOverride,
  }) {
    final String exe = exeOverride?.isNotEmpty == true
        ? exeOverride!
        : '$root/bin/katago.exe';
    if (!File(exe).existsSync()) {
      throw KataGoException(KataGoError.exeMissing, exe);
    }

    String model = modelOverride ?? '';
    if (model.isEmpty) {
      final Directory dir = Directory('$root/models');
      if (dir.existsSync()) {
        for (final FileSystemEntity f in dir.listSync()) {
          if (f is File && (f.path.endsWith('.bin.gz') || f.path.endsWith('.bin'))) {
            model = f.path;
            break;
          }
        }
      }
    }
    if (model.isEmpty || !File(model).existsSync()) {
      throw KataGoException(KataGoError.modelMissing, model);
    }

    String config = configOverride ?? '';
    if (config.isEmpty) {
      for (final String c in <String>[
        '$root/gtp_play.cfg',
        '$root/default_gtp.cfg',
        '$root/bin/default_gtp.cfg',
      ]) {
        if (File(c).existsSync()) {
          config = c;
          break;
        }
      }
    }
    if (config.isEmpty || !File(config).existsSync()) {
      throw KataGoException(KataGoError.configMissing, config);
    }

    return KataGoPaths(exe: exe, model: model, config: config);
  }
}

/// GTP 응답 블록을 파싱한다. '=' 성공, '?' 실패.
/// 브리지의 프레이밍 로직을 그대로 옮겼다 — 순수 함수라 테스트할 수 있다.
sealed class GtpResponse {
  const GtpResponse();
}

final class GtpOk extends GtpResponse {
  const GtpOk(this.payload);
  final String payload;
}

final class GtpRejected extends GtpResponse {
  const GtpRejected(this.message);
  final String message;
}

final class GtpEmpty extends GtpResponse {
  const GtpEmpty();
}

GtpResponse parseGtpBlock(String block) {
  for (final String raw in block.split('\n')) {
    final String line = raw.trimRight();
    if (line.startsWith('=')) {
      return GtpOk(line.substring(1).trim());
    }
    if (line.startsWith('?')) {
      return GtpRejected(line.substring(1).trim());
    }
  }
  return const GtpEmpty();
}

class KataGoProcess {
  KataGoProcess();

  Process? _proc;
  final List<_Pending> _pending = <_Pending>[];
  final StringBuffer _buffer = StringBuffer();
  final StreamController<String> _stderr = StreamController<String>.broadcast();
  StreamSubscription<String>? _outSub;
  StreamSubscription<String>? _errSub;

  /// OpenCL 최초 튜닝 진행이 여기로 나온다 — UI 가 반드시 보여줘야 한다
  Stream<String> get stderrLog => _stderr.stream;

  bool get isRunning => _proc != null;

  Future<void> start(KataGoPaths paths) async {
    if (_proc != null) return;
    try {
      _proc = await Process.start(
        paths.exe,
        <String>['gtp', '-model', paths.model, '-config', paths.config],
      );
    } on Object catch (e) {
      throw KataGoException(KataGoError.startFailed, '$e');
    }

    _outSub = _proc!.stdout
        .transform(utf8.decoder)
        .listen(_onStdout, onDone: () => _fail(KataGoError.exited));
    _errSub =
        _proc!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
              (String line) {
                if (!_stderr.isClosed) _stderr.add(line);
              },
            );
    unawaited(_proc!.exitCode.then((_) => _fail(KataGoError.exited)));
  }

  /// GTP 는 빈 줄로 응답 블록을 끝낸다
  void _onStdout(String chunk) {
    _buffer.write(chunk);
    String text = _buffer.toString();
    while (true) {
      final Match? m = RegExp(r'\r?\n\r?\n').firstMatch(text);
      if (m == null) break;
      final String block = text.substring(0, m.start);
      text = text.substring(m.end);
      _deliver(block);
    }
    _buffer
      ..clear()
      ..write(text);
  }

  /// GTP 는 순차라 선입선출로 짝지어도 안전하다
  void _deliver(String block) {
    if (_pending.isEmpty) return;
    final _Pending p = _pending.removeAt(0);
    if (p.completer.isCompleted) return;
    switch (parseGtpBlock(block)) {
      case GtpOk(:final String payload):
        p.completer.complete(payload);
      case GtpRejected(:final String message):
        p.completer.completeError(KataGoException(KataGoError.rejected, message));
      case GtpEmpty():
        p.completer.completeError(
            const KataGoException(KataGoError.emptyResponse));
    }
  }

  /// 프로세스가 죽으면 대기 중인 요청을 전부 깨운다 — 영원히 매달리지 않게
  void _fail(KataGoError error) {
    _proc = null;
    while (_pending.isNotEmpty) {
      final _Pending p = _pending.removeAt(0);
      if (!p.completer.isCompleted) {
        p.completer.completeError(KataGoException(error, p.command));
      }
    }
  }

  Future<String> send(
    String command, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    final Process? proc = _proc;
    if (proc == null) {
      return Future<String>.error(const KataGoException(KataGoError.notRunning));
    }
    final Completer<String> c = Completer<String>();
    _pending.add(_Pending(command, c));
    proc.stdin.writeln(command);
    return c.future.timeout(
      timeout,
      onTimeout: () => throw KataGoException(KataGoError.timeout, command),
    );
  }

  /// 탐색은 오래 걸린다 — 브리지가 쓰던 90초를 그대로 유지
  Future<String> genmove(String color) =>
      send('genmove $color', timeout: const Duration(seconds: 90));

  /// quit → 종료 대기 → 강제 종료.
  /// 앱이 닫힐 때 katago.exe 가 남으면 GPU 메모리를 물고 있다.
  Future<void> stop() async {
    final Process? proc = _proc;
    if (proc == null) return;
    try {
      proc.stdin.writeln('quit');
      await proc.exitCode.timeout(const Duration(seconds: 3));
    } on Object catch (_) {
      proc.kill(ProcessSignal.sigterm);
      try {
        await proc.exitCode.timeout(const Duration(seconds: 2));
      } on Object catch (_) {
        proc.kill(ProcessSignal.sigkill);
      }
    } finally {
      await _outSub?.cancel();
      await _errSub?.cancel();
      _fail(KataGoError.exited);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _stderr.close();
  }
}

/// 엔진 보드를 우리 수순과 맞춘다.
/// 매 수 clear_board 는 GPU 에서도 체감될 만큼 느려서, 공통 접두사 뒤만 보낸다.
/// (React 판 katago.ts 의 핵심 로직 — 그대로 옮겼다)
int historyPrefixMatch(List<String> engine, List<String> wanted) {
  final int n = engine.length < wanted.length ? engine.length : wanted.length;
  int i = 0;
  for (; i < n; i++) {
    if (engine[i] != wanted[i]) break;
  }
  return i;
}
