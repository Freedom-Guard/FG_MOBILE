import 'dart:math';

import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/components/update.dart';

class BackgroundService {
  static final List<String> _backgrounds = [
    "10.jpg",
    "5.jpg",
    "15.jpg",
    "14.jpg",
    "4.jpg",
    "17.jpg",
    "background.jpg"
  ];

  static String getRandomBackground() {
    final random = Random();
    return "assets/${_backgrounds[random.nextInt(_backgrounds.length)]}";
  }
}

class checker {
  static Settings settings = new Settings();

  static checkVPN() async {
    initSettings();
    return await checkForVPN();
  }

  static initSettings() async {
    if (await settings.getValue("core_vpn") == "")
      settings.setValue("core_vpn", "auto");
  }
}
