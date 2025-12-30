import 'dart:math';

String getStatusText(String type) {
  final random = Random();

  final connectedTexts = [
    "🕊️ Freedom is in your hands",
    "✅ Connection secure",
    "🛡️ Protected and empowered",
    "🌐 Online safely",
    "🚀 Ready to explore"
  ];

  final disconnectedTexts = [
    "Tap to connect 🔌",
    "💡 Connect to unlock freedom",
    "🔓 Unlock your connection",
    "🚀 Tap the button ",
    "🕊️ Freedom is waiting"
  ];                                 

  if (type == "connected") {
    return connectedTexts[random.nextInt(connectedTexts.length)];
  } else if (type == "disconnected") {
    return disconnectedTexts[random.nextInt(disconnectedTexts.length)];
  } else {
    return "";
  }
}
