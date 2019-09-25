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

// private class
@immutable
class _FijkVolChange {
  final double vol;
  final bool ui;
  final int type;

  _FijkVolChange({
    @required this.vol,
    @required this.ui,
    @required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FijkVolChange &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode => hashValues(vol, ui, type);
}

/// Fijk System Volume Manger
class FijkVolume extends ChangeNotifier
    implements ValueListenable<_FijkVolChange> {
  FijkVolume._();

  static const int STREAM_VOICE_CALL = 0;
  static const int STREAM_SYSTEM = 1;
  static const int STREAM_RING = 2;
  static const int STREAM_MUSIC = 3;
  static const int STREAM_ALARM = 4;

  /// show system volume changed UI if no playable player
  /// hide system volume changed UI if some players are in playable state
  static const int hideUIWhenPlayable = 0;

  /// show system volume changed UI if no start state player
  /// hide system volume changed UI if some players are in start state
  static const int hideUIWhenPlaying = 1;

  /// never show system volume changed UI
  static const int neverShowUI = 2;

  /// always show system volume changed UI
  static const int alwaysShowUI = 3;

  static FijkVolume _instance = FijkVolume._();

  _FijkVolChange _value;

  @override
  _FijkVolChange get value => _value;

  /// Mute system volume
  /// return system volume after mute
  static Future<double> systemVolumeMute() {
    return FijkPlugin._channel.invokeMethod("volumeMute");
  }

  /// set system volume to [vol]
  /// the range of [vol] is [0.0, 1,0]
  /// return the system volume value after set
  static Future<double> systemVolumeSet(double vol) {
    if (vol == null) {
      return Future.error(ArgumentError.notNull("vol"));
    } else {
      return FijkPlugin._channel
          .invokeMethod("volumeSet", <String, dynamic>{'vol': vol});
    }
  }

  /// increase system volume by step
  /// return the system volume value after increase
  static Future<double> systemVolumeUp() {
    return FijkPlugin._channel.invokeMethod("volumeUp");
  }

  /// decrease system volume by step
  /// return the system volume value after decrease
  static Future<double> systemVolumeDown() {
    return FijkPlugin._channel.invokeMethod("volumeDown");
  }

  /// update the ui mode when system volume changed
  /// mode can be one of
  /// {[hideUIWhenPlayable], [hideUIWhenPlaying], [neverShowUI], [alwaysShowUI]}
  static Future<void> setSystemVolumeUIMode(int mode) {
    if (mode == null)
      return Future.error(ArgumentError.notNull("mode"));
    else
      return FijkPlugin._channel
          .invokeMethod("volUiMode", <String, dynamic>{'mode': mode});
  }

  void _onVolCallback(double vol, bool ui) {
    _value = _FijkVolChange(vol: vol, ui: ui, type: STREAM_MUSIC);
    notifyListeners();
  }
}

/// Volume changed callback func.
///
/// [vol] is the value of volume, and has been mapped into range [0.0, 1.0]
/// true value of [ui] indicates that Android/iOS system volume changed UI is shown for this volume change event
/// [streamType] shows track\stream type for this volume change, this value is always [FijkVolume.STREAM_MUSIC] in this version
typedef FijkVolumeCallback = void Function(double vol, bool ui, int streamType);

/// stateful widget that watching system volume, no ui widget
/// when system volume changed, [watcher] will be invoked.
class FijkVolumeWatcher extends StatefulWidget {
  /// volume changed callback
  final FijkVolumeCallback watcher;

  /// child widget, must be non-null
  final Widget child;

  /// whether show default volume changed toast, default value is false.
  ///
  /// The default toast ui insert an OverlayEntry to current context's overlay
  final bool showToast;

  FijkVolumeWatcher({
    @required this.watcher,
    @required this.child,
    bool showToast = false,
  })  : assert(child != null),
        showToast = showToast;

  @override
  _FijkVolumeWatcherState createState() => _FijkVolumeWatcherState();
}

class _FijkVolumeWatcherState extends State<FijkVolumeWatcher> {
  OverlayEntry _entry;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    FijkPlugin._onLoad("vol");
    FijkVolume._instance.addListener(volChanged);
  }

  void volChanged() {
    _FijkVolChange value = FijkVolume._instance.value;

    if (widget.watcher != null) {
      widget.watcher(value.vol, value.ui, value.type);
    }
    if (widget.showToast && !value.ui) {
      showVolToast(value.vol);
    }
  }

  /// reference https://www.kikt.top/posts/flutter/toast/oktoast/
  void showVolToast(double vol) {
    bool active = _timer?.isActive;
    _timer?.cancel();
    Widget widget = _FijkVolToast();
    if (active == null || active == false) {
      _entry = OverlayEntry(builder: (_) => widget);
      Overlay.of(context).insert(_entry);
    }
    _timer = Timer(const Duration(milliseconds: 1500), () {
      _entry?.remove();
    });
  }

  @override
  void dispose() {
    super.dispose();
    FijkVolume._instance.removeListener(volChanged);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _FijkVolToast extends StatefulWidget {
  @override
  __FijkVolToastState createState() => __FijkVolToastState();
}

class __FijkVolToastState extends State<_FijkVolToast> {
  double vol;

  @override
  void initState() {
    super.initState();
    vol = FijkVolume._instance.value.vol;
    FijkVolume._instance.addListener(volChanged);
  }

  void volChanged() {
    _FijkVolChange value = FijkVolume._instance.value;
    setState(() {
      vol = value.vol;
    });
  }

  @override
  void dispose() {
    super.dispose();
    FijkVolume._instance.removeListener(volChanged);
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.volume_up;

    if (vol <= 0) {
      iconData = Icons.volume_mute;
    } else if (vol < 0.5) {
      iconData = Icons.volume_down;
    } else {
      iconData = Icons.volume_up;
    }

    String v = (vol * 100).toStringAsFixed(0);
    return Align(
      alignment: Alignment(0, -0.6),
      child: Container(
          color: Color(0x44554444),
          padding: EdgeInsets.all(5),
          decoration: null,
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                iconData,
                color: Colors.white,
                size: 30.0,
              ),
              Text(
                v,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  decoration: null,
                ),
              )
            ],
          )),
    );
  }
}
