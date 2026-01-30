import 'package:dart_promise/dart_promise.dart';

typedef Task = Future<bool> Function();

class PromiseRunner {
  static Future<bool> runWithTimeout(Task task, {required Duration timeout}) {
    return Promise<bool>((resolve, reject) {
      bool completed = false;

      Future.delayed(timeout, () {
        if (!completed) {
          completed = true;
          resolve(false);
        }
      });

      task().then((result) {
        if (!completed) {
          completed = true;
          resolve(result);
        }
      }).catchError((_) {
        if (!completed) {
          completed = true;
          resolve(false);
        }
      });
    }).toFuture();
  }
}
