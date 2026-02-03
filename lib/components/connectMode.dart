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
  GlobalFGB.connStatText.value = "🤖 Smart connection in progress…";
  if (await connectFlMode(context)) return true;
  if (await connectRepoMode(context)) return true;
  LogOverlay.addLog("Auto connection attempts failed");
  return false;
}

Future<bool> connectFlMode(BuildContext context) async {
  GlobalFGB.connStatText.value =
      "🚀 Searching for the best configuration (FL Mode)…";
  return await (PromiseRunner.runWithTimeout(
    connectFL,
    timeout: const Duration(seconds: 150),
  )) ?? false;
}

Future<bool> connectRepoMode(BuildContext context) async {
  GlobalFGB.connStatText.value =
      "📡 Evaluating available configurations (Repo Mode)…";
  final settings = Provider.of<SettingsApp>(context, listen: false);
  int timeout =
      int.tryParse(await settings.getValue("timeout_auto").toString()) ??
          200000;

  return await (PromiseRunner.runWithTimeout(
    (token) => connect.ConnectFG(defSet["fgconfig"]!, timeout, token: token),
    timeout: Duration(milliseconds: timeout),
  )) ?? false;
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
