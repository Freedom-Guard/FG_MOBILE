import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

bool isTvPlatform = false;

Future<void> checkAndroidTv() async {
  if (kIsWeb || !Platform.isAndroid) {
    isTvPlatform = false;
    return;
  }

  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.systemFeatures.contains('android.software.leanback') ||
        androidInfo.systemFeatures.contains('android.software.live_tv')) {
      isTvPlatform = true;
    } else {
      isTvPlatform = false;
    }
  } catch (e) {
    isTvPlatform = false;
  }
}
