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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'fijkplugin.dart';

/// The data source type for fijkplayer
/// [asset] [network] and [file]
enum DateSourceType {
  /// [asset] means source from app asset files
  asset,

  /// [network] means source from network. it supports many protocols, like `http` and `rtmp` etc.
  network,

  /// [file] means source from the phone's storage
  file,

  /// player will try to detect data type when passed [unknown]
  unknown,
}

/// State of the Player
///
/// This is the state machine of player.
/// The state changed after method called or when some error occurs.
/// One state can only change into the new state it can reach.
///
/// For example, [IDLE] can't becomes [ASYNC_PREPARING] directly.
///
/// Todo, make a picture which can show the state change
enum FijkState {
  /// setDataSource  -> [INITIALIZED]
  ///
  /// reset          -> self
  ///
  /// release        -> [END]
  ///
  IDLE,

  ///
  /// prepareAsync   -> [ASYNC_PREPARING]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  ///
  INITIALIZED,

  ///
  /// .....          -> [PREPARED]
  ///
  /// .....          -> [ERROR]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  ///
  ASYNC_PREPARING,

  ///
  /// start          -> [STARTED]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  PREPARED,

  /// start          -> self
  ///
  /// pause          -> [PAUSED]
  ///
  /// stop           -> [STOPPED]
  ///
  /// ......         -> [COMPLETED]
  ///
  /// ......         -> [ERROR]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  STARTED,

  /// start          -> [STARTED]
  ///
  /// pause          -> self
  ///
  /// stop           -> [STOPPED]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  PAUSED,

  /// start          -> [STARTED] (from beginning)
  ///
  /// pause          -> self
  ///
  /// stop           -> [STOPPED]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  COMPLETED,

  /// stop           -> self
  ///
  /// prepareAsync   -> [ASYNC_PREPARING]
  ///
  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  STOPPED,

  /// reset          -> [IDLE]
  ///
  /// release        -> [END]
  ERROR,

  /// release        -> self
  END
}

@immutable
class FijkValue {
  /// Indicates if the player is ready
  final bool prepared;

  /// Indicates if the player is completed
  ///
  /// If the playback stream is realtime/live, [completed] never be true.
  final bool completed;

  /// The pixel [size] of current video
  ///
  /// Is null when [prepared] is false.
  /// Is negative width and height if playback is audio only.
  final Size size;

  /// The current playback duration
  ///
  /// Is null when [prepared] is false.
  /// Is zero when playback is realtime stream.
  final Duration duration;

  /// The [dateSourceType] of current playback.
  ///
  /// Is [DateSourceType.unknown] when [prepared] is false.
  final DateSourceType dateSourceType;

  /// whether if player should be displayed as in full screen
  final bool fullScreen;

  /// A constructor requires all value.
  const FijkValue({
    @required this.prepared,
    @required this.completed,
    @required this.size,
    @required this.duration,
    @required this.dateSourceType,
    @required this.fullScreen,
  });

  /// Construct FijkValue with uninitialized value
  const FijkValue.uninitialized()
      : this(
            prepared: false,
            completed: false,
            size: null,
            duration: const Duration(),
            dateSourceType: DateSourceType.unknown,
            fullScreen: false);

  /// Return new FijkValue which combines the old value and the assigned new value
  FijkValue copyWith(
      {bool prepared,
      bool completed,
      Size size,
      Duration duration,
      DateSourceType dateSourceType,
      bool fullScreen}) {
    return FijkValue(
      prepared: prepared ?? this.prepared,
      completed: completed ?? this.completed,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      dateSourceType: dateSourceType ?? this.dateSourceType,
      fullScreen: fullScreen ?? this.fullScreen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FijkValue &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode => hashValues(
      prepared, completed, size, duration, dateSourceType, fullScreen);

  @override
  String toString() {
    return "prepared:$prepared, completed:$completed, size:$size, "
        "dataType:$dateSourceType duration:$duration, fullScreen:$fullScreen";
  }
}

class FijkPlayer extends ValueNotifier<FijkValue> {
  String _dataSource;
  DateSourceType _dateSourceType;

  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  StreamSubscription _looperSub;

  bool _startAfterSetup = false;

  FijkState _epState;
  FijkState _fpState;

  /// return the current state
  FijkState get state => _fpState;

  final StreamController<FijkState> _playerStateController =
      StreamController.broadcast();

  Stream<FijkState> get onPlayerStateChanged => _playerStateController.stream;

  Duration _bufferPos = Duration();

  /// return the current buffered position
  Duration get bufferPos => _bufferPos;

  final StreamController<Duration> _bufferPosController =
      StreamController.broadcast();

  Stream<Duration> get onBufferPosUpdate => _bufferPosController.stream;

  Duration _currentPos = Duration();

  /// return the current playing position
  Duration get currentPos => _currentPos;

  final StreamController<Duration> _currentPosController =
      StreamController.broadcast();

  Stream<Duration> get onCurrentPosUpdate => _currentPosController.stream;

  bool _buffering = false;

  /// return true if the player is buffering
  bool get isBuffering => _buffering;

  final StreamController<bool> _bufferStateController =
      StreamController.broadcast();

  Stream<bool> get onBufferStateUpdate => _bufferStateController.stream;

  String get dataSource => _dataSource;

  final Completer<int> _nativeSetup;

  FijkPlayer()
      : _nativeSetup = Completer(),
        super(FijkValue.uninitialized()) {
    _fpState = FijkState.IDLE;
    _epState = FijkState.ERROR;
    _doNativeSetup();
  }

  Future<void> _startFromAnyState() async {
    await _nativeSetup.future;

    if (_epState == FijkState.ERROR || _epState == FijkState.STOPPED) {
      await reset();
    }
    if (_epState == FijkState.IDLE) {
      await setDataSource(_dateSourceType, _dataSource);
    }
    if (_epState == FijkState.INITIALIZED) {
      await prepareAsync();
    }
    if (_epState == FijkState.PREPARED ||
        _epState == FijkState.COMPLETED ||
        _epState == FijkState.PAUSED) {
      await start();
    }
    return Future.value();
  }

  Future<void> _doNativeSetup() async {
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    _epState = FijkState.IDLE;

    print("native player id: $_playerId");

    _nativeEventSubscription =
        EventChannel('befovy.com/fijkplayer/event/' + _playerId.toString())
            .receiveBroadcastStream()
            .listen(_eventListener, onError: errorListener);
    _nativeSetup.complete(_playerId);

    if (_startAfterSetup) {
      await _startFromAnyState();
    }

    _looperSub = Stream.periodic(const Duration(milliseconds: 200), (v) => v)
        .listen(_looper);
    _looperSub.pause();
  }

  Future<int> setupSurface() async {
    await _nativeSetup.future;
    return _channel.invokeMethod("setupSurface");
  }

  Future<int> setDataSource(DateSourceType type, String path) async {
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == FijkState.IDLE) {
      Map<String, dynamic> dataSourceDescription;
      _dateSourceType = type;
      _dataSource = path;
      switch (_dateSourceType) {
        case DateSourceType.network:
          dataSourceDescription = <String, dynamic>{'url': _dataSource};
          break;
        case DateSourceType.asset:
          break;
        case DateSourceType.file:
          break;
        case DateSourceType.unknown:
          break;
      }
      _epState = FijkState.INITIALIZED;
      value = value.copyWith(dateSourceType: type);
      await _channel.invokeMethod("setDateSource", dataSourceDescription);
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<int> prepareAsync() async {
    // ckeck state
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == FijkState.INITIALIZED) {
      _epState = FijkState.PREPARED;
      await _channel.invokeMethod("prepareAsync");
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<void> setVolume(double volume) async {
    await _nativeSetup.future;
    return _channel
        .invokeMethod("setVolume", <String, dynamic>{"volume": volume});
  }

  /// Toggle full screen value.
  /// Return the value after toggle.
  bool toggleFullScreen() {
    bool full = value.fullScreen;
    value = value.copyWith(fullScreen: !full);
    return !full;
  }

  Future<int> start() async {
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == FijkState.INITIALIZED) {
      await _channel.invokeMethod("prepareAsync");
      await _channel.invokeMethod("start");
      _epState = FijkState.STARTED;
    } else if (_epState == FijkState.PREPARED || _epState == FijkState.PAUSED) {
      await _channel.invokeMethod("start");
      _epState = FijkState.STARTED;
    } else if (_epState == FijkState.PAUSED) {
      ret = -1;
    }

    print("call start $_epState");
    return Future.value(ret);
  }

  Future<int> pause() async {
    await _nativeSetup.future;
    _epState = FijkState.PAUSED;
    await _channel.invokeMethod("pause");
    print("call pause");
    return Future.value(0);
  }

  Future<int> stop() async {
    await _nativeSetup.future;

    _epState = FijkState.STOPPED;
    await _channel.invokeMethod("stop");
    return Future.value(0);
  }

  Future<int> reset() async {
    await _nativeSetup.future;

    await _channel.invokeMethod("reset");
    return Future.value(0);
  }

  Future<void> release() async {
    await _nativeSetup.future;
    await this.stop();
    await _nativeEventSubscription.cancel();
    await _looperSub.cancel();
    return FijkPlugin.releasePlayer(_playerId);
  }

  void _looper(int timer) {
    _channel.invokeMethod("getCurrentPosition").then((pos) {
      _currentPos = Duration(milliseconds: pos);
      _currentPosController.add(_currentPos);
      //debugPrint("currentPos $_currentPos");
    });
  }

  void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'prepared':
        int duration = map['duration'];
        Duration dur = Duration(milliseconds: duration);
        value = value.copyWith(duration: dur, prepared: true);
        debugPrint("duration: $dur");
        break;
      case 'state_change':
        int newState = map['new'];
        int oldState = map['old'];
        _fpState = FijkState.values[newState];

        if (_fpState == FijkState.STARTED) {
          _looperSub.resume();
          print("_looper resume");
        } else {
          if (!_looperSub.isPaused) _looperSub.pause();
        }

        if (_fpState == FijkState.ERROR) {
          _epState = FijkState.ERROR;
        }
        _playerStateController.add(_fpState);
        print(_fpState.toString() + " <= " + _epState.toString());

        var o = FijkState.values[oldState];
        print("new $_fpState <= old $o");
        if (newState == FijkState.PREPARED.index) {
          value = value.copyWith(prepared: true);
        } else if (newState < FijkState.PREPARED.index) {
          value = value.copyWith(prepared: false);
        }
        break;
      case 'freeze':
        bool value = map['value'];
        _buffering = value;
        _bufferStateController.add(value);
        print(value ? "buffer $value start" : "buffer $value end");
        break;

      case 'buffering':
        int head = map['head'];
        // int percent = map['percent'];
        _bufferPos = Duration(milliseconds: head);
        _bufferPosController.add(_bufferPos);
        break;
      case 'size_changed':
        int width = map['width'];
        int height = map['height'];
        print("size_changed buffer $width, $height");

        value = value.copyWith(size: Size(width.toDouble(), height.toDouble()));
        break;
      default:
        break;
    }
  }

  void errorListener(Object obj) {
    final PlatformException e = obj;
    print("onError: $e");
  }
}
