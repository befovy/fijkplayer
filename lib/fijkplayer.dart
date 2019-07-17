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

  /// A constructor requires all value.
  const FijkValue({
    @required this.prepared,
    @required this.size,
    @required this.duration,
    @required this.dateSourceType,
  });

  /// Construct FijkValue with uninitialized value
  const FijkValue.uninitialized()
      : this(
            prepared: false,
            size: null,
            duration: null,
            dateSourceType: DateSourceType.unknown);

  /// Return new FijkValue which combines the old value and the assigned new value
  FijkValue copyWith(
      {bool prepared,
      Size size,
      Duration duration,
      DateSourceType dateSourceType}) {
    return FijkValue(
      prepared: prepared ?? this.prepared,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      dateSourceType: dateSourceType ?? this.dateSourceType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FijkValue &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode => hashValues(size, duration, prepared);
}

class FijkPlayer extends ValueNotifier<FijkValue> {
  String _dataSource;
  DateSourceType _dateSourceType;

  FijkState _fpState;
  FijkState _epState;
  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  bool _startAfterSetup = false;
  bool _buffering = false;
  Duration _bufferPos = Duration();
  Duration _currentPos = Duration();

  StreamSubscription _looperSub;

  final StreamController<FijkState> _playerStateController =
      StreamController.broadcast();

  final StreamController<Duration> _bufferPosController =
      StreamController.broadcast();

  final StreamController<Duration> _currentPosController =
      StreamController.broadcast();

  final StreamController<bool> _bufferStateController =
      StreamController.broadcast();

  String get dataSource => _dataSource;

  /// return the current state
  FijkState get state => _fpState;

  /// return the current buffered position
  Duration get bufferPos => _bufferPos;

  /// return the current playing position
  Duration get currentPos => _currentPos;

  /// return true if the player is buffering
  bool get isBuffering => _buffering;

  Stream<FijkState> get onPlayerStateChanged => _playerStateController.stream;

  Stream<Duration> get onBufferPosUpdate => _bufferPosController.stream;

  Stream<bool> get onBufferStateUpdate => _bufferStateController.stream;

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

    if (_fpState == FijkState.STARTED) {
      _channel.invokeMethod("getCurrentPosition").then((pos) {
        _currentPos = Duration(milliseconds: pos);
        _currentPosController.add(_currentPos);
        debugPrint("currentPos $_currentPos");
      });
    }
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
          if (!_looperSub.isPaused)
            _looperSub.pause();
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
