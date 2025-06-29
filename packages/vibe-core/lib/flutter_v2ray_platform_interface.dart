import 'package:flutter_v2ray/model/v2ray_status.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_v2ray_method_channel.dart';

abstract class FlutterV2rayPlatform extends PlatformInterface {
  /// Constructs a FlutterV2rayPlatform.
  FlutterV2rayPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterV2rayPlatform _instance = MethodChannelFlutterV2ray();

  /// The default instance of [FlutterV2rayPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterV2ray].
  static FlutterV2rayPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterV2rayPlatform] when
  /// they register themselves.
  static set instance(FlutterV2rayPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<void> initializeV2Ray({
    required void Function(V2RayStatus status) onStatusChanged,
    required String notificationIconResourceType,
    required String notificationIconResourceName,
  }) {
    throw UnimplementedError('initializeV2Ray() has not been implemented.');
  }

  Future<void> startV2Ray({
    required String remark,
    required String config,
    required String notificationDisconnectButtonName,
    List<String>? blockedApps,
    List<String>? bypassSubnets,
    bool proxyOnly = false,
  }) {
    throw UnimplementedError('startV2Ray() has not been implemented.');
  }

  Future<void> stopV2Ray() {
    throw UnimplementedError('stopV2Ray() has not been implemented.');
  }

  Future<int> getServerDelay({required String config, required String url}) {
    throw UnimplementedError('getServerDelay() has not been implemented.');
  }

  Future<int> getConnectedServerDelay(String url) async {
    throw UnimplementedError(
      'getConnectedServerDelay() has not been implemented.',
    );
  }

  Future<String> getCoreVersion() async {
    throw UnimplementedError(
      'getCoreVersion() has not been implemented.',
    );
  }
}
