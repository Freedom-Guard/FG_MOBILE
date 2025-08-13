import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/global.dart';
import 'package:Freedom_Guard/components/services.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:quick_settings/quick_settings.dart';

Future<bool> toggleQuick() async {
  var selectedServer = "";
  if (((await Settings().getValue("config_backup")) != "") &&
      (selectedServer.split("#")[0].isEmpty ||
          selectedServer.split("#")[0].startsWith("http"))) {
    selectedServer = (await Settings().getValue("config_backup"));
    LogOverlay.showToast("Conneting to QUICK mode...");
  }
  if (await checker.checkVPN()) {
    LogOverlay.showToast("Disconnecting...");
    await connect.disConnect();
    await Future.delayed(Duration(seconds: 1));
    LogOverlay.showToast("Disconnected!");
  } else {
    if (selectedServer == "") {
      LogOverlay.showToast("Please connect once from within the app.");
      return false;
    }
    return await connect.ConnectVibe(selectedServer, {});
  }
  return false;
}

@pragma('vm:entry-point')
Future<Tile> onTileClicked(Tile tile) async {
  final oldStatus = tile.tileStatus;
  final connStatus = await toggleQuick();
  if (oldStatus == TileStatus.active) {
    tile.label = "Guard OFF";
    tile.tileStatus = TileStatus.inactive;
    tile.subtitle = "Disconnected";
    tile.drawableName = "security_off";
  } else if (connStatus) {
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
