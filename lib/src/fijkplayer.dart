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
enum FijkSourceType {
  // [asset] means source from app asset files
  // asset,

  /// [network] means source from network. it supports many protocols, like `http` and `rtmp` etc.
  network,

  /// [file] means source from the phone's storage
  /// file,

  /// player will try to detect data type when passed [unknown]
  unknown,
}

/// State of the [FijkPlayer]
///
/// This is the state machine of ijkplayer. FijkPlayer has the same state as native ijkplayer.
/// The state changed after method called or when some error occurs.
/// One state can only change into the new state it can reach.
///
/// For example, [idle] can't becomes [asyncPreparing] directly.
///
/// <img width="800" src="https://user-images.githubusercontent.com/51129600/62750997-ab195100-ba94-11e9-941b-57509e2bd677.png" />
enum FijkState {
  /// The state when a [FijkPlayer] is just created.
  /// Native ijkplayer memory and objects also be alloced or created when a [FijkPlayer] is created.
  ///
  /// * setDataSource()  -> [initialized]
  /// * reset()          -> self
  /// * release()        -> [end]
  idle,

  /// After call [FijkPlayer.setDataSource] on state [idle], the state becomes [initialized].
  ///
  /// * prepareAsync()   -> [asyncPreparing]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  initialized,

  /// There're many tasks to do during prepare, such as detect stream info in datasource, find and open decoder, start decode and refresh thread.
  /// So ijkplayer export a async api prepareAsync.
  /// When [FijkPlayer.prepareAsync] is called on state [initialized], ths state changed to [asyncPreparing] immediately.
  /// After all task in prepare have finished, the state changed to [prepared].
  /// Additionally, if any error occurs during prepare, the state will change to [error].
  ///
  /// * .....            -> [prepared]
  /// * .....            -> [error]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  asyncPreparing,

  /// After finish all the heavy tasks during [FijkPlayer.prepareAsync],
  /// the state becomes [prepared] from [asyncPreparing].
  ///
  /// * seekTo()         -> self
  /// * start()          -> [started]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  prepared,

  /// * seekTo()         -> self
  /// * start()          -> self
  /// * pause()          -> [paused]
  /// * stop()           -> [stopped]
  /// * ......           -> [completed]
  /// * ......           -> [error]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  started,

  /// * seekTo()         -> self
  /// * start()          -> [started]
  /// * pause()          -> self
  /// * stop()           -> [stopped]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  paused,

  /// * seekTo()         -> [paused]
  /// * start()          -> [started] (from beginning)
  /// * pause()          -> self
  /// * stop()           -> [stopped]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  completed,

  /// * stop()           -> self
  /// * prepareAsync()   -> [asyncPreparing]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  stopped,

  /// * reset()          -> [idle]
  /// * release()        -> [end]
  error,

  /// * release()        -> self
  end
}

/// FijkValue include the properties of a [FijkPlayer] which update not frequently.
///
/// To get the updated value of other frequently updated properties,
/// add listener of the value stream.
/// See
///  * [FijkPlayer.onBufferPosUpdate]
///  * [FijkPlayer.onCurrentPosUpdate]
///  * [FijkPlayer.onBufferStateUpdate]
@immutable
class FijkValue {
  /// Indicates if the player is ready
  final bool prepared;

  /// Indicates if the player is completed
  ///
  /// If the playback stream is realtime/live, [completed] never be true.
  final bool completed;

  /// Current state of the player
  final FijkState state;

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
  /// Is [FijkSourceType.unknown] when [prepared] is false.
  final FijkSourceType dateSourceType;

  /// whether if player should be displayed in full screen mode
  final bool fullScreen;

  /// A constructor requires all value.
  const FijkValue({
    @required this.prepared,
    @required this.completed,
    @required this.state,
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
          state: FijkState.idle,
          size: null,
          duration: const Duration(),
          dateSourceType: FijkSourceType.unknown,
          fullScreen: false,
        );

  /// Return new FijkValue which combines the old value and the assigned new value
  FijkValue copyWith({
    bool prepared,
    bool completed,
    FijkState state,
    Size size,
    Duration duration,
    FijkSourceType dateSourceType,
    bool fullScreen,
  }) {
    return FijkValue(
      prepared: prepared ?? this.prepared,
      completed: completed ?? this.completed,
      state: state ?? this.state,
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
      prepared, completed, state, size, duration, dateSourceType, fullScreen);

  @override
  String toString() {
    return "prepared:$prepared, completed:$completed, state:$state, size:$size, "
        "dataType:$dateSourceType duration:$duration, fullScreen:$fullScreen";
  }
}

/// FijkPlayer present as a playback. It interacts with native object.
///
/// FijkPlayer invoke native method and receive native event.
class FijkPlayer extends ChangeNotifier implements ValueListenable<FijkValue> {
  String _dataSource;

  FijkSourceType _dateSourceType;

  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  StreamSubscription _looperSub;

  bool _startAfterSetup = false;

  FijkValue _value;
  FijkState _epState;

  /// return the current state
  FijkState get state => _value.state;

  @override
  FijkValue get value => _value;

  void _setValue(FijkValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

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

  /// stream of current playing position, update every 200ms.
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
        super() {
    _value = FijkValue.uninitialized();
    _epState = FijkState.error;
    _doNativeSetup();
  }

  Future<void> _startFromAnyState() async {
    await _nativeSetup.future;

    if (_epState == FijkState.error || _epState == FijkState.stopped) {
      await reset();
    }
    if (_epState == FijkState.idle) {
      await setDataSource(_dataSource, type: _dateSourceType);
    }
    if (_epState == FijkState.initialized) {
      await prepareAsync();
    }
    if (_epState == FijkState.prepared ||
        _epState == FijkState.completed ||
        _epState == FijkState.paused) {
      await start();
    }
    return Future.value();
  }

  Future<void> _doNativeSetup() async {
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    _epState = FijkState.idle;

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

  Future<int> setDataSource(String path,
      {FijkSourceType type = FijkSourceType.network,
      bool autoPlay = false}) async {
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == FijkState.idle) {
      Map<String, dynamic> dataSourceDescription;
      _dateSourceType = type;
      _dataSource = path;
      switch (_dateSourceType) {
        case FijkSourceType.network:
          dataSourceDescription = <String, dynamic>{'url': _dataSource};
          break;
        //case FijkSourceType.asset:
        //  break;
        //case FijkSourceType.file:
        //  break;
        case FijkSourceType.unknown:
          break;
      }
      _epState = FijkState.initialized;
      _setValue(value.copyWith(dateSourceType: type));
      await _channel.invokeMethod("setDateSource", dataSourceDescription);

      if (autoPlay == true) {
        await this.start();
      }
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<int> prepareAsync() async {
    // ckeck state
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == FijkState.initialized) {
      _epState = FijkState.prepared;
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
    _setValue(value.copyWith(fullScreen: !full));
    return !full;
  }

  Future<int> start() async {
    await _nativeSetup.future;
    int ret = 0;

    if (_epState == FijkState.initialized) {
      await _channel.invokeMethod("prepareAsync");
      await _channel.invokeMethod("start");
      _epState = FijkState.started;
    } else if (_epState == FijkState.prepared ||
        _epState == FijkState.paused ||
        value.state == FijkState.completed) {
      await _channel.invokeMethod("start");
      _epState = FijkState.started;
    } else {
      ret = -1;
    }

    print("call start $_epState ${value.state} ret:$ret");
    return Future.value(ret);
  }

  Future<int> pause() async {
    await _nativeSetup.future;
    _epState = FijkState.paused;
    await _channel.invokeMethod("pause");
    print("call pause");
    return Future.value(0);
  }

  Future<int> stop() async {
    await _nativeSetup.future;

    _epState = FijkState.stopped;
    await _channel.invokeMethod("stop");
    return Future.value(0);
  }

  Future<int> reset() async {
    await _nativeSetup.future;
    _epState = FijkState.idle;
    await _channel.invokeMethod("reset");
    return Future.value(0);
  }

  Future<int> seekTo(int msec) async {
    await _nativeSetup.future;

    // if (_epState == )
    await _channel.invokeMethod("seekTo", <String, dynamic>{"msec": msec});
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
        _setValue(value.copyWith(duration: dur, prepared: true));
        break;
      case 'state_change':
        int newState = map['new'];
        FijkState fpState = FijkState.values[newState];

        if (fpState == FijkState.started) {
          _looperSub.resume();
        } else {
          if (!_looperSub.isPaused) _looperSub.pause();
        }

        if (fpState == FijkState.error) {
          _epState = FijkState.error;
        }

        if (newState == FijkState.prepared.index) {
          _setValue(value.copyWith(prepared: true, state: fpState));
        } else if (newState < FijkState.prepared.index) {
          _setValue(value.copyWith(prepared: false, state: fpState));
        } else {
          _setValue(value.copyWith(state: fpState));
        }
        break;
      case 'freeze':
        bool value = map['value'];
        _buffering = value;
        _bufferStateController.add(value);
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
        _setValue(
            value.copyWith(size: Size(width.toDouble(), height.toDouble())));
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
