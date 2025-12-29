import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/core/async_runner.dart';
import 'package:Freedom_Guard/core/defSet.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

connectAutoMode(BuildContext context) async {
  GlobalFGB.connStatText.value = "Trying to connect automatically...";
  final settings = Provider.of<SettingsApp>(context, listen: false);
  var connStat = false;
  connStat = await connectFlMode(context);
  if (!connStat) {
    connStat = await connectRepoMode(context);
  }
  return connStat;
}

connectFlMode(BuildContext context) async {
  GlobalFGB.connStatText.value = "Connecting using FL mode...";
  var connStat = false;
  LogOverlay.showLog("connecting to FL mode...");
  connStat = await CancellableRunner.runWithTimeout(
    (token) async {
      return await connectFL(token);
    },
    timeout: Duration(seconds: 1020),
  );
  return connStat;
}

connectRepoMode(BuildContext context) async {
  GlobalFGB.connStatText.value = "Connecting using Repository mode...";
  final settings = Provider.of<SettingsApp>(context, listen: false);
  var connStat = false;
  LogOverlay.showLog(
    "connecting to Repo mode...",
    backgroundColor: Colors.blueAccent,
  );
  var timeout = int.tryParse(
        await settings.getValue("timeout_auto").toString(),
      ) ??
      110000;
  connStat = await connect.ConnectFG(
    defSet["fgconfig"]!,
    110000,
  ).timeout(
    Duration(milliseconds: timeout),
    onTimeout: () {
      LogOverlay.showLog("Connection to Auto mode timed out.", type: "error");
      return connect.isConnected;
    },
  );
  return connStat;
}

connectAutoMy(BuildContext context) async {
  GlobalFGB.connStatText.value = "Connecting using Repository mode...";
  final serverM = Provider.of<ServersM>(context, listen: false);
  List servers = await serverM.oldServers();
  var connStat = false;
  connStat = await connectAutoVibe(servers);
  return connStat;
}

connectAutoVibe(List listConfigs) async {
  GlobalFGB.connStatText.value = "";
  for (String config in listConfigs) {
    bool connStat = false;

    if (config.startsWith("http")) {
      connStat = await connect.ConnectSub(config, "sub");
    } else if (connect.testConfig(config) != -1) {
      connStat = await connect.ConnectVibe(config, {});
    }

    if (connStat) {
      LogOverlay.showLog("Connected successfully.");
      return true;
    }
  }

  LogOverlay.showLog("No working user configs found.", type: "warn");
  return false;
}
