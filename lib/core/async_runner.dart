import 'dart:async';
import 'dart:isolate';

typedef Task = Future<bool> Function();

class PromiseRunner {
  static Future<bool> runWithTimeout(
    Task task, {
    required Duration timeout,
  }) async {
    final receivePort = ReceivePort();
    late Isolate isolate;

    isolate = await Isolate.spawn<_IsolatePayload>(
      _isolateEntry,
      _IsolatePayload(task, receivePort.sendPort),
    );

    try {
      final result = await receivePort.first.timeout(timeout);
      isolate.kill(priority: Isolate.immediate);
      return result as bool;
    } on TimeoutException {
      isolate.kill(priority: Isolate.immediate);
      return false;
    } finally {
      receivePort.close();
    }
  }
}

class _IsolatePayload {
  final Task task;
  final SendPort sendPort;

  _IsolatePayload(this.task, this.sendPort);
}

void _isolateEntry(_IsolatePayload payload) async {
  try {
    final result = await payload.task();
    payload.sendPort.send(result);
  } catch (_) {
    payload.sendPort.send(false);
  }
}
