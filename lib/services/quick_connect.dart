import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/services.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:quick_settings/quick_settings.dart';

toggleQuick() async {
  try {
    await WidgetsFlutterBinding.ensureInitialized();

    var selectedServer = (await Settings().getValue("config_backup"));
    print(selectedServer);
    if (await checker.checkVPN()) {
      LogOverlay.showToast("Disconnecting...");
      await Connect().disConnect();
      await Future.delayed(Duration(seconds: 1));
      LogOverlay.showToast("Disconnected!");
    } else {
      if (selectedServer == "") {
        LogOverlay.showToast("Please connect once from within the app.");
        return false;
      }
      LogOverlay.showToast("Connecting to QUICK mode... \n " + selectedServer);
      await Connect().ConnectVibe(selectedServer, {}, typeDis: "quick");
      LogOverlay.showToast("Connected!");
    }
  } catch (e) {
    print("Error in toggleQuick: $e");
  }
  return false;
}

@pragma('vm:entry-point')
Tile onTileClicked(Tile tile) {
  final oldStatus = tile.tileStatus;

  toggleQuick();

  if (oldStatus == TileStatus.active) {
    tile.label = "Guard OFF";
    tile.tileStatus = TileStatus.inactive;
    tile.subtitle = "Disconnected";
    tile.drawableName = "security_off";
  } else {
    tile.label = "Guard ON";
    tile.tileStatus = TileStatus.active;
    tile.subtitle = "Protected";
    tile.drawableName = "security_on";
  }
  print("Guard Tile status: ${tile.tileStatus}");
  return tile;
}

@pragma('vm:entry-point')
Tile onTileAdded(Tile tile) {
  tile.label = "Guard OFF";
  tile.tileStatus = TileStatus.inactive;
  tile.subtitle = "Disconnected";
  tile.drawableName = "security_off";
  LogOverlay.addLog("Guard Tile Added");
  return tile;
}

@pragma('vm:entry-point')
void onTileRemoved() {
  LogOverlay.addLog("Guard Tile Removed");
}
