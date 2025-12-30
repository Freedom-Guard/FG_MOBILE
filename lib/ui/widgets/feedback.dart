import 'package:flutter/material.dart';
import 'package:Freedom_Guard/utils/url.dart';

void showFeedbackDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1A2A44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Feedback & Links",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              _linkButton(
                icon: Icons.telegram,
                color: Colors.blueAccent,
                label: "Telegram",
                url: "https://t.me/Freedom_Guard_Net",
              ),
              _linkButton(
                icon: Icons.public,
                color: Colors.greenAccent,
                label: "Feedback Website",
                url: "https://feedback.freedomguard.workers.dev",
              ),
              _linkButton(
                icon: Icons.code,
                color: Colors.orangeAccent,
                label: "GitHub",
                url: "https://github.com/Freedom-Guard/FG_Mobile/issues",
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

Widget _linkButton(
    {required IconData icon,
    required Color color,
    required String label,
    required String url}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: InkWell(
      onTap: () => openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white, size: 18)
          ],
        ),
      ),
    ),
  );
}
