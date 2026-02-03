import 'dart:async';
import 'package:Freedom_Guard/utils/LOGLOG.dart';

typedef Task<T> = Future<T> Function(CancellationToken token);

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
  static Future<T?> runWithTimeout<T>(
    Task<T> task, {
    required Duration timeout,
  }) async {
    final token = CancellationToken();
    final timer = Timer(timeout, () {
      token.cancel();
    });

    try {
      return await task(token);
    } catch (e) {
      LogOverlay.addLog(e.toString());
      return null;
    } finally {
      timer.cancel();
      if (!token.isCancelled) {
        token.cancel();
      }
    }
  }
}
