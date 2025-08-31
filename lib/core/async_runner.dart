// lib/utils/async_runner.dart
import 'dart:async';
import 'dart:isolate';

class AsyncRunner {
  /// Run [task] with [timeout] in a separate isolate.
  /// - Returns result if completed
  /// - Returns false if timeout or error
  static Future<bool> runWithTimeout(
    FutureOr<bool> Function() task, {
    required Duration timeout,
  }) async {
    final response = ReceivePort();
    final isolate = await Isolate.spawn<_TaskMessage>(
      _isolateEntry,
      _TaskMessage(task, response.sendPort),
    );

    try {
      final result = await response.first.timeout(timeout, onTimeout: () {
        isolate.kill(priority: Isolate.immediate);
        return false;
      });

      return result as bool;
    } catch (_) {
      return false;
    } finally {
      response.close();
    }
  }

  static void _isolateEntry(_TaskMessage msg) async {
    try {
      final value = await msg.task();
      msg.sendPort.send(value);
    } catch (_) {
      msg.sendPort.send(false);
    }
  }
}

class _TaskMessage {
  final FutureOr<bool> Function() task;
  final SendPort sendPort;
  _TaskMessage(this.task, this.sendPort);
}
