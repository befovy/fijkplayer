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

import 'dart:io';

import 'package:flutter/services.dart';

import 'fijkplayer.dart';
import 'fijkview.dart';

/// for inner use, don't use this directly in app.
/// use [FijkPlayer] and [FijkView] instead.
class FijkPlugin {
  static const MethodChannel _channel = const MethodChannel('befovy.com/fijk');

  static Future<String> get platformVersion {
    return _channel.invokeMethod('getPlatformVersion');
  }

  static Future<int> createPlayer() {
    return _channel.invokeMethod("createPlayer");
  }

  static Future<void> releasePlayer(int pid) {
    return _channel
        .invokeMethod("releasePlayer", <String, dynamic>{'pid': pid});
  }

  static Future<void> setLogLevel(int level) {
    return _channel.invokeMethod("logLevel", <String, dynamic>{'level': level});
  }

  static Future<void> setOrientationPortrait() {
    // ios crash Supported orientations has no common orientation with the application
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    return _channel.invokeMethod("setOrientationPortrait");
  }

  static Future<void> setOrientationLandscape() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    return _channel.invokeMethod("setOrientationLandscape");
  }

  static Future<void> setOrientationAuto() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    return _channel.invokeMethod("setOrientationAuto");
  }
}
