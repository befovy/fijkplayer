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

part of fijkplayer;

class FijkPlugin {
  static const MethodChannel _channel = const MethodChannel('befovy.com/fijk');

  static Future<int> _createPlayer() {
    return _channel.invokeMethod("createPlayer");
  }

  static Future<void> _releasePlayer(int pid) {
    return _channel
        .invokeMethod("releasePlayer", <String, dynamic>{'pid': pid});
  }

  static bool isDesktop() {
    return Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isFuchsia;
  }

  /// Only works on Android and iOS
  static Future<void> setOrientationPortrait() {
    if (isDesktop()) return Future.value();
    // ios crash Supported orientations has no common orientation with the application
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    return _channel.invokeMethod("setOrientationPortrait");
  }

  /// Only works on Android and iOS
  /// return false if current orientation is landscape
  /// return true if current orientation is portrait and after this API
  /// call finished, the orientation becomes landscape.
  /// return false if can't change orientation.
  static Future<bool> setOrientationLandscape() {
    if (isDesktop()) return Future.value(false);
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

  /// Only works on Android
  /// request audio focus for media usage
  static Future<void> requestAudioFocus() {
    if (Platform.isAndroid) {
      return _channel.invokeMethod("requestAudioFocus");
    }
    return Future.value();
  }

  /// Only works on Android
  /// release audio focus
  static Future<void> releaseAudioFocus() {
    if (Platform.isAndroid) {
      return _channel.invokeMethod("releaseAudioFocus");
    }
    return Future.value();
  }

  static Future<void> _setLogLevel(int level) {
    return _channel.invokeMethod("logLevel", <String, dynamic>{'level': level});
  }

  static StreamSubscription _eventSubs;

  static void _onLoad(String type) {
    if (_eventSubs == null) {
      FijkLog.i("_onLoad $type");
      _eventSubs = EventChannel("befovy.com/fijk/event")
          .receiveBroadcastStream()
          .listen(FijkPlugin._eventListener,
              onError: FijkPlugin._errorListener);
    }
    _channel.invokeMethod("onLoad");
  }

  // ignore: unused_element
  static void _onUnload() {
    FijkLog.i("_onUnload");
    _channel.invokeMethod("onUnload");
    _eventSubs?.cancel();
  }

  static void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    FijkLog.d("plugin listener: $map");
    switch (map['event']) {
      case 'volume':
        bool sui = map['sui'];
        double vol = map['vol'];
        FijkVolume._instance._onVolCallback(vol, sui);
        break;
      default:
        break;
    }
  }

  static void _errorListener(Object obj) {
    FijkLog.e("plugin errorListerner: $obj");
  }
}
