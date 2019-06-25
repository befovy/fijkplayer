import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijkplayer/fijkplugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('fijkplayer');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FijkPlugin.platformVersion, '42');
  });
}
