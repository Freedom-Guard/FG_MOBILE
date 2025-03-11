import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class CoreService {
  static Future<void> showHelpDialog(BuildContext context) async {
    String output = await _runHelp();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hiddify Help"),
          content: SingleChildScrollView(
            child: Text(output, style: const TextStyle(fontSize: 14)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("باشه"),
            ),
          ],
        );
      },
    );
  }

  static Future<String> _runHelp() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final corePath = "${dir.path}/core/vibe/vibe-core";
      final newPath = "/data/local/tmp/vibe-core";
      await File(corePath).copy(newPath);
      await Process.run('chmod', ['777', newPath]);
      ProcessResult result = await Process.run(newPath, ['--help']);
      if (!await File(corePath).exists()) {
        return "هسته پیدا نشد: $corePath";
      }

      if (result.exitCode != 0) {
        return "خطا در اتمام: ${result.stderr}";
      }

      if (result.stdout is String) {
        return result.stdout;
      } else if (result.stdout is List<int>) {
        try {
          return utf8.decode(result.stdout);
        } catch (e) {
          File outputFile = File("${dir.path}/core/output.bin");
          await outputFile.writeAsBytes(result.stdout);
          return "خروجی باینری بود و در فایل ذخیره شد!";
        }
      }

      return "هیچ خروجی‌ای دریافت نشد!";
    } catch (e) {
      return "خطا در اجرا: $e";
    }
  }
}
