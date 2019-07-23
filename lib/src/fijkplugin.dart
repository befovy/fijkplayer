//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  static Future<void> setOrientationPortrait(
      {@required BuildContext context}) async {
    final platform = Theme.of(context).platform;

    // ios crash Supported orientations has no common orientation with the application
    if (platform == TargetPlatform.android) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    return _channel.invokeMethod("setOrientationPortrait");
  }

  static Future<void> setOrientationLandscape(
      {@required BuildContext context}) async {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    return _channel.invokeMethod("setOrientationLandscape");
  }

  static Future<void> setOrientationAuto(
      {@required BuildContext context}) async {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    return _channel.invokeMethod("setOrientationAuto");
  }
}
