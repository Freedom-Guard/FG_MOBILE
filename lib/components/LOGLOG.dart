import 'package:flutter/material.dart';

class LogOverlay {
  static OverlayEntry? _overlayEntry;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showLog(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Context not available yet: $message'); // لاگ موقت توی کنسول
      return;
    }

    // حذف لاگ قبلی
    _overlayEntry?.remove();
    _overlayEntry = null;

    // ایجاد لاگ جدید
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 50.0,
            left: 10.0,
            right: 10.0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ),
    );

    // نمایش لاگ
    Overlay.of(context).insert(_overlayEntry!);

    // حذف خودکار بعد از مدت زمان
    Future.delayed(duration, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  static void hideLog() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
