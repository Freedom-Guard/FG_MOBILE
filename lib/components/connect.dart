import 'package:flutter_v2ray/flutter_v2ray.dart';

class Connect {
  ConnectVibe(config, args) async {
    final FlutterV2ray flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        // do something
      },
    );

    // You must initialize V2Ray before using it.
    await flutterV2ray.initializeV2Ray();

    // v2ray share link like vmess://, vless://, ...
    String link = config;
    V2RayURL parser = FlutterV2ray.parseFromURL(link);

    // Get Server Delay
    print(
      '${flutterV2ray.getServerDelay(config: parser.getFullConfiguration())}ms',
    );

    // Permission is not required if you using proxy only
    if (await flutterV2ray.requestPermission()) {
      flutterV2ray.startV2Ray(
        remark: parser.remark,
        // The use of parser.getFullConfiguration() is not mandatory,
        // and you can enter the desired V2Ray configuration in JSON format
        config: parser.getFullConfiguration(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );
    }
  }
}
