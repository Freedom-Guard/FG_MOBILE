import 'dart:async';

class CancelToken {
  bool _canceled = false;
  void cancel() => _canceled = true;
  bool get isCanceled => _canceled;
}

class CancellableRunner {
  static Future<bool> runWithTimeout(
    Future<bool> Function(CancelToken token) task, {
    required Duration timeout,
  }) async {
    final token = CancelToken();
    try {
      return await task(token).timeout(
        timeout,
        onTimeout: () {
          token.cancel();
          return false;
        },
      );
    } catch (_) {
      return false;
    }
  }
}
