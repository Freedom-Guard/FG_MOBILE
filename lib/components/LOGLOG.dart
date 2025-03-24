import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clipboard/clipboard.dart';

class LogOverlay {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<_LogData> _logQueue = [];
  static bool _isShowingLog = false;

  static Future<void> addLog(String message) async {
    try {
      final now = DateTime.now();
      final logMessage = '[${now.toIso8601String()}] $message\n';
      final file = await _getLogFile();
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsString(
        logMessage,
        mode: FileMode.append,
        encoding: utf8,
      );
    } catch (e, stackTrace) {
      debugPrint('Error writing log: $e\nStackTrace: $stackTrace');
    }
  }

  static Future<String> loadLogs() async {
    try {
      final file = await _getLogFile();
      if (!await file.exists()) {
        return '';
      }
      try {
        return await file.readAsString(encoding: utf8);
      } catch (e) {
        try {
          return await file.readAsString(encoding: latin1);
        } catch (e) {
          final bytes = await file.readAsBytes();
          return bytes.toString();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error reading logs: $e\nStackTrace: $stackTrace');
      return '';
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      debugPrint('Error clearing logs: $e\nStackTrace: $stackTrace');
    }
  }

  static Future<bool> copyLogs() async {
    try {
      final logs = await loadLogs();
      if (logs.isEmpty) {
        return false;
      }
      await FlutterClipboard.copy(logs);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error copying logs: $e\nStackTrace: $stackTrace');
      return false;
    }
  }

  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/app_logs.txt');
  }

  static void showLog(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
  }) {
    addLog(message);
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
