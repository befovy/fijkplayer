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

/// Show Mode of System Volume changed UI
enum FijkVolUIMode {
  /// show system volume changed UI if no playable player
  /// hide system volume changed UI if some players are in playable state
  hideUIWhenPlayable,

  /// show system volume changed UI if no start state player
  /// hide system volume changed UI if some players are in start state
  hideUIWhenPlaying,

  /// never show system volume changed UI
  neverShowUI,

  /// always show system volume changed UI
  alwaysShowUI,
}

typedef FijkSysVolCallback = void Function(double vol, bool sysUIShown);

/// Fijk System Volume Manger
class FijkVol {
  FijkVol._();

  static FijkSysVolCallback _volCallback;

  /// Mute system volume
  static Future<double> systemVolumeMute() {
    return FijkPlugin._channel.invokeMethod("volumeMute");
  }

  /// set system volume to [vol]
  /// the range of [vol] is [0.0, 1,0]
  static Future<double> systemVolumeSet(double vol) {
    if (vol == null) {
      return Future.error(ArgumentError.notNull("vol"));
    } else {
      return FijkPlugin._channel
          .invokeMethod("volumeSet", <String, dynamic>{'vol': vol});
    }
  }

  /// increase system volume by step
  static Future<double> systemVolumeUp() {
    return FijkPlugin._channel.invokeMethod("volumeUp");
  }

  /// decrease system volume by step
  static Future<double> systemVolumeDown() {
    return FijkPlugin._channel.invokeMethod("volumeDown");
  }

  /// update the ui mode when system volume changed
  /// see [FijkVolUIMode] for detail
  static Future<void> setSystemVolumeUIMode(FijkVolUIMode mode) {
    if (mode == null)
      return Future.error(ArgumentError.notNull("mode"));
    else
      return FijkPlugin._channel
          .invokeMethod("volUiMode", <String, dynamic>{'mode': mode.index});
  }

  static void setSystemVolumeCallback(FijkSysVolCallback callback) {
    _volCallback = callback;
  }

  static void _onVolCallback(double vol, bool sysUIShown) {
    FijkLog.i("vol: $vol, sysUI: $sysUIShown");
    if (_volCallback != null) {
      _volCallback(vol, sysUIShown);
    }
  }
}
