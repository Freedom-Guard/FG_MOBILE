import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void shareConfig(BuildContext context) async {
  final config = await SettingsApp().getValue("config_backup");

  await Share.share(
    config,
    subject: "My FG Config",
  );
}
