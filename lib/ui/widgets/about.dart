import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/ui/widgets/link.dart';
import 'package:flutter/material.dart';

class AboutDialogWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/icon/ico.png", width: 100, height: 100),
            const SizedBox(height: 10),
            const Text(
              "Freedom Guard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "9.7.0",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            SelectableText(
              tr("about-app"),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 30,
              children: [
                LinkWidget(
                  url: "https://github.com/Freedom-Guard/FG_MOBILE",
                  text: "GitHub",
                  icon: Icons.code,
                ),
                LinkWidget(
                  url: "https://t.me/Freedom_Guard_Net",
                  text: "Telegram",
                  icon: Icons.open_in_new,
                ),
                LinkWidget(
                  url: "https://freedom-guard.github.io/privacy-terms.html",
                  text: "Privacy & Terms",
                  icon: Icons.open_in_new,
                ),
                LinkWidget(
                  url: "https://x.com/Freedom_Guard_N",
                  text: "X",
                  icon: Icons.open_in_new,
                ),
              ],
            ),
            const SizedBox(
              height: 25,
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 32,
                ),
              ),
              child: Text(
                tr("close"),
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
