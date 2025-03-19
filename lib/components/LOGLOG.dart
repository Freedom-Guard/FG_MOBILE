import 'package:flutter/material.dart';

class LogOverlay {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<_LogData> _logQueue = [];
  static bool _isShowingLog = false;

  static void showLog(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87, // رنگ پیش‌فرض
  }) {
    _logQueue.add(_LogData(message, duration, backgroundColor));
    _processQueue();
  }

  static void _processQueue() {
    if (_isShowingLog || _logQueue.isEmpty) return;

    _isShowingLog = true;
    final logData = _logQueue.removeAt(0);
    _showSnackBar(logData.message, logData.duration, logData.backgroundColor);
  }

  static void _showSnackBar(
    String message,
    Duration duration,
    Color backgroundColor,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Context not available yet: $message');
      _isShowingLog = false;
      return;
    }

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor.withOpacity(0.8),
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      _isShowingLog = false;
      _processQueue();
    });
  }

  static void hideLog() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    _logQueue.clear();
    _isShowingLog = false;
  }
}

class _LogData {
  final String message;
  final Duration duration;
  final Color backgroundColor;

  _LogData(this.message, this.duration, this.backgroundColor);
}
