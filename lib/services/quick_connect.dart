import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/global.dart';
import 'package:Freedom_Guard/components/services.dart';
import 'package:Freedom_Guard/components/settings.dart';

toggleQuick() async {
  var selectedServer = "";
  if (((await Settings().getValue("config_backup")) != "") &&
      (selectedServer.split("#")[0].isEmpty ||
          selectedServer.split("#")[0].startsWith("http"))) {
    if ((await connect
            .testConfig(await Settings().getValue("config_backup"))) !=
        -1) {
      selectedServer = (await Settings().getValue("config_backup"));
      LogOverlay.addLog("Conneting to QUICK mode...");
    }
  }
  if (await checker.checkVPN()) {
    await connect.disConnect();
  } else {
    if (selectedServer == "") {
      LogOverlay.showLog("Please connect once from within the app.");
    }
    await connect.ConnectVibe(selectedServer, {});
  }
}
