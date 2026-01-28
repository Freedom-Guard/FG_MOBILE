import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class LogOverlay {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final List<_LogData> _logQueue = [];
  static final List<String> _logs = [];

  static bool _isShowingLog = false;

  static void addLog(String message) {
    print(message);
    final now = DateTime.now();
    final logMessage =
        '[${now.toIso8601String()}] ${message.replaceAll("\n", "")}';
    _logs.add(logMessage);
  }

  static String loadLogs() => _logs.join('\n');

  static void clearLogs() => _logs.clear();

  static Future<bool> copyLogs() async {
    try {
      final logs = loadLogs();
      if (logs.isEmpty) return false;
      await FlutterClipboard.copy(logs);
      return true;
    } catch (e) {
      debugPrint('Error copying logs: $e');
      return false;
    }
  }

  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16.0,
    );
    addLog(message);
  }

  static void showModal(
    String message,
    String telegramLink, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    VoidCallback? onAdTap,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    addLog(message);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ModalContent(
          message: message,
          telegramLink: telegramLink,
          duration: duration,
          backgroundColor: backgroundColor,
          onAdTap: onAdTap,
        );
      },
    );
  }

  static Future<int> showRatingModal(
      String message, String telegramLink, String docId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return -1;

    addLog("Showing rating modal for config: $docId");

    final rating = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _RatingModalContent(
          message: message,
          docId: docId,
        );
      },
    );

    return rating ?? -1;
  }

  static void showLog(String message,
      {Duration duration = const Duration(seconds: 3),
      Color backgroundColor = Colors.black87,
      String type = "info"}) {
    addLog(message);
    Color textColor;
    backgroundColor = type == "info"
        ? Colors.blueAccent
        : type == "error"
            ? Colors.redAccent
            : type == "success"
                ? Colors.greenAccent
                : type == "warning"
                    ? Colors.orangeAccent
                    : type == "rating"
                        ? Colors.amber
                        : type == "debug"
                            ? Colors.purpleAccent
                            : type == "critical"
                                ? Colors.red.shade900
                                : type == "notification"
                                    ? Colors.tealAccent
                                    : type == "info_light"
                                        ? Colors.lightBlue
                                        : type == "success_light"
                                            ? Colors.green.shade300
                                            : Colors.black87;

    textColor = type == "info_light" || type == "success_light"
        ? Colors.black87
        : Colors.white;

    _logQueue.add(_LogData(message, duration, backgroundColor, textColor));
    _processQueue();
  }

  static void _processQueue() {
    if (_isShowingLog || _logQueue.isEmpty) return;
    _isShowingLog = true;
    final logData = _logQueue.removeAt(0);
    _showSnackBar(logData.message, logData.duration, logData.backgroundColor,
        logData.textColor);
  }

  static void _showSnackBar(
    String message,
    Duration duration,
    Color backgroundColor,
    Color textColor,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _isShowingLog = false;
      return;
    }

    final snackBar = SnackBar(
      content: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: backgroundColor.withOpacity(0.85),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
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
  final Color textColor;

  _LogData(this.message, this.duration, this.backgroundColor,
      [this.textColor = Colors.white]);
}

class _ModalContent extends StatefulWidget {
  final String message;
  final String telegramLink;
  final Duration duration;
  final Color backgroundColor;
  final VoidCallback? onAdTap;

  const _ModalContent({
    required this.message,
    required this.telegramLink,
    required this.duration,
    required this.backgroundColor,
    this.onAdTap,
  });

  @override
  State<_ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<_ModalContent> {
  bool _isExitEnabled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isExitEnabled = true);
      }
    });
  }

  Future<void> openTelegram(String telegramLink) async {
    String link = telegramLink;
    if (link.startsWith("@")) {
      link = "https://t.me/${link.substring(1)}";
    }
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.white.withOpacity(0.25);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.35);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تبلیغات اهدا کننده',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isExitEnabled
                          ? () => Navigator.of(context).maybePop()
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: _isExitEnabled
                            ? Colors.red.shade600
                            : Colors.grey.shade800.withOpacity(0.6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isExitEnabled ? 2 : 0,
                      ),
                      child: const Text(
                        'خروج',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (widget.telegramLink.isNotEmpty)
                      TextButton(
                        onPressed: () => openTelegram(widget.telegramLink),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'مشاهده کانال',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<int> showRatingModal(String message, String docId) async {
  final context = LogOverlay.navigatorKey.currentContext;
  if (context == null) {
    return -1;
  }

  final rating = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _RatingModalContent(
        message: message,
        docId: docId,
      );
    },
  );

  return rating ?? 3;
}

class _RatingModalContent extends StatefulWidget {
  final String message;
  final String docId;

  const _RatingModalContent({
    required this.message,
    required this.docId,
  });

  @override
  State<_RatingModalContent> createState() => _RatingModalContentState();
}

class _RatingModalContentState extends State<_RatingModalContent>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  bool _isExitEnabled = false;

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isExitEnabled = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: colors.surface.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'امتیاز به کانفیگ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final active = _rating > index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _rating = index + 1);
                        },
                        child: AnimatedScale(
                          scale: active ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              active
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: active
                                  ? Colors.amber
                                  : colors.onSurface.withOpacity(0.4),
                              size: 34,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isExitEnabled && _rating > 0
                              ? () => Navigator.of(context).pop(_rating)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            disabledBackgroundColor: colors.surfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text('ارسال'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(-1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                            side: BorderSide(color: colors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('لغو'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
