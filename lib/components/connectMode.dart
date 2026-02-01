import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/core/async_runner.dart';
import 'package:Freedom_Guard/core/defSet.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


Future<bool> connectAutoMode(BuildContext context) async {
  GlobalFGB.connStatText.value = "🤖 Trying to connect automatically…";
  if (await connectFlMode(context)) return true;
  if (await connectRepoMode(context)) return true;
  LogOverlay.addLog("Auto connection attempts failed");
  return false;
}

Future<bool> connectFlMode(BuildContext context) async {
  LogOverlay.addLog("Starting FL mode connection");
  return await PromiseRunner.runWithTimeout(
    (port) async {
      final ok = await connectFL();
      port.send(IsolateMessage('result', ok));
    },
    timeout: const Duration(seconds: 120),
  );
}

Future<bool> connectRepoMode(BuildContext context) async {
  LogOverlay.addLog("Starting Repo mode connection");
  final settings = Provider.of<SettingsApp>(context, listen: false);
  int timeout =
      int.tryParse(await settings.getValue("timeout_auto").toString()) ??
          200000;

  return await PromiseRunner.runWithTimeout(
    (port) async {
      final ok = await connect.ConnectFG(defSet["fgconfig"]!, timeout);
      port.send(IsolateMessage('result', ok));
    },
    timeout: Duration(milliseconds: timeout),
  );
}

Future<bool> connectAutoMy(BuildContext context) async {
  final serverM = Provider.of<ServersM>(context, listen: false);
  final servers = await serverM.oldServers();
  return await connectAutoVibe(servers);
}

Future<bool> connectAutoVibe(List listConfigs) async {
  LogOverlay.addLog("Starting Auto Vibe connection");
  listConfigs.shuffle();
  for (String config in listConfigs) {
    bool ok = false;
    if (config.startsWith("http")) {
      ok = await connect.ConnectSub(config, "sub");
    } else if (await connect.testConfig(config) != -1) {
      ok = await connect.ConnectVibe(config, {});
    }
    if (ok) {
      LogOverlay.addLog("Connected successfully via Auto Vibe");
      return true;
    }
  }
  LogOverlay.addLog("Auto Vibe connection failed");
  return false;
}
