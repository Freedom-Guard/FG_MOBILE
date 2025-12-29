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

  void openTelegram(String telegramLink) async {
    if (telegramLink.startsWith("@")) {
      telegramLink = "https://t.me/" + telegramLink.split("@")[1];
    }
    final uri = Uri.parse(telegramLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      LogOverlay.showLog(
        "Cannot open the link.",
        type: "error",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.backgroundColor.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  'تبلیغات اهدا کننده',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (widget.telegramLink != "")
                    TextButton(
                      onPressed: () => openTelegram(widget.telegramLink),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('مشاهده کانال'),
                    ),
                  const SizedBox(width: 20),
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: TextButton(
                        onPressed: _isExitEnabled
                            ? () => Navigator.of(context).maybePop()
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: _isExitEnabled
                              ? Colors.red
                              : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('خروج'),
                      )),
                ],
              ),
            ],
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

class _RatingModalContentState extends State<_RatingModalContent> {
  int _rating = 0;
  bool _isExitEnabled = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isExitEnabled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  'امتیاز به کانفیگ',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    icon: Icon(
                      _rating > index ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isExitEnabled && _rating > 0
                        ? () => Navigator.of(context).pop(_rating)
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: _isExitEnabled && _rating > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('ارسال'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(-1),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('لغو'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
