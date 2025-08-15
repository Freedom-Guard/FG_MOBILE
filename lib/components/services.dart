import 'dart:math';

import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/components/update.dart';

class BackgroundService {
  static final List<String> _backgrounds = [
    "10.jpg",
    "15.jpg",
    "4.png",
    "17.png",
    "background.png"
  ];

  static String getRandomBackground() {
    final random = Random();
    return "assets/${_backgrounds[random.nextInt(_backgrounds.length)]}";
  }
}

class checker {
  static SettingsApp settings = new SettingsApp();

  static checkVPN() async {
    initSettings();
    return await checkForVPN();
  }

  static initSettings() async {
    if (await settings.getValue("core_vpn") == "")
      settings.setValue("core_vpn", "auto");
  }
}
