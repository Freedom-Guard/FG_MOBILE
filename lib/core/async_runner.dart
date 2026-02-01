import 'dart:async';
import 'dart:isolate';
import 'package:Freedom_Guard/utils/LOGLOG.dart';

typedef IsolateTask = Future<void> Function(SendPort sendPort);

class IsolateMessage {
  final String type;
  final dynamic data;

  IsolateMessage(this.type, this.data);
}

class PromiseRunner {
  static Future<bool> runWithTimeout(
    IsolateTask task, {
    required Duration timeout,
  }) async {
    final receivePort = ReceivePort();
    late Isolate isolate;
    bool result = false;

    isolate = await Isolate.spawn<_IsolatePayload>(
      _isolateEntry,
      _IsolatePayload(task, receivePort.sendPort),
    );

    try {
      await receivePort.cast<IsolateMessage>().timeout(timeout).forEach((msg) {
        if (msg.type == 'log') {
          LogOverlay.addLog(msg.data.toString());
        } else if (msg.type == 'result') {
          result = msg.data == true;
          isolate.kill(priority: Isolate.immediate);
        }
      });
    } on TimeoutException {
      isolate.kill(priority: Isolate.immediate);
      result = false;
    } finally {
      receivePort.close();
    }

    return result;
  }
}

class _IsolatePayload {
  final IsolateTask task;
  final SendPort sendPort;

  _IsolatePayload(this.task, this.sendPort);
}

void _isolateEntry(_IsolatePayload payload) async {
  try {
    await payload.task(payload.sendPort);
  } catch (e) {
    payload.sendPort.send(IsolateMessage('log', e.toString()));
    payload.sendPort.send(IsolateMessage('result', false));
  }
}
