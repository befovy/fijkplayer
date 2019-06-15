import 'package:flutter/services.dart';

class FijkPlugin {
  static const MethodChannel _channel = const MethodChannel('befovy.com/fijk');

  static Future<String> get platformVersion async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  static Future<int> createPlayer() async {
    return await _channel.invokeMethod("createPlayer");
  }

  static Future<void> releasePlayer(int pid) async {
    return await _channel
        .invokeMethod("releasePlayer", <String, dynamic>{'pid': pid});
  }
}
