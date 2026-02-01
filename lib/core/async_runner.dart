import 'dart:async';
import 'package:Freedom_Guard/utils/LOGLOG.dart';

typedef Task = Future<void> Function(CancellationToken token);

class CancellationToken {
  bool _isCancelled = false;
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _isCancelled;

  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _completer.complete();
    }
  }
}

class PromiseRunner {
  static Future<bool> runWithTimeout(
    Task task, {
    required Duration timeout,
  }) async {
    final token = CancellationToken();
    bool result = false;

    final timer = Timer(timeout, () {
      token.cancel();
    });

    try {
      await task(token);
      result = true;
    } catch (e) {
      LogOverlay.addLog(e.toString());
      result = false;
    } finally {
      timer.cancel();
      if (!token.isCancelled) {
        token.cancel();
      }
    }

    return result;
  }
}
