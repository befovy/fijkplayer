import 'package:flutter/services.dart';

class FijkPlugin {
  static const MethodChannel _channel = const MethodChannel('befovy.com/fijk');

  static Future<String> get platformVersion async {
    await _channel.invokeMethod(
      "init",
      <String, dynamic>{'textureId': 0x000},
    );
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> createIjkPlayer() async {
    final String channel = await _channel.invokeMethod(
      "createPlayer",
      <String, dynamic>{},
    );
    return channel;
  }

  static Future<String> createIjkView() async {
    final String channel = await _channel.invokeMethod(
      "createView",
      <String, dynamic>{},
    );
    return channel;
  }
}
