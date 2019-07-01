import 'dart:async';
import 'package:flutter/services.dart';

import 'fijkplugin.dart';

/// The data source type for the player
/// [asset] [network] and [file]
enum DateSourceType {
  /// [asset] means source from app asset files
  asset,

  /// [network] means source from network. it supports many protocols, like `http` and `rtmp` etc.
  network,

  /// [file] means source from the phone's storage
  file
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

  /// reset        -> [IDLE]
  /// 
  /// release      -> [END]
  ERROR,

  /// release      -> self
  END
}

class FijkPlayer {
  String dataSource;
  DateSourceType dateSourceType;

  FijkState _fpState;
  FijkState _epState;
  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  bool _buffering = false;
  Duration _bufferPos = Duration();

  // Duration _duration;
  // DurationRange _bufferd;

  final StreamController<FijkState> _playerStateController =
      StreamController.broadcast();

  final StreamController<Duration> _bufferPosController =
      StreamController.broadcast();

  final StreamController<bool> _bufferStateController =
      StreamController.broadcast();

  FijkState get state => _fpState;
  Duration get bufferPos => _bufferPos;
  bool get isBuffering => _buffering;

  Stream<FijkState> get onPlayerStateChanged => _playerStateController.stream;
  Stream<Duration> get onBufferPosUpdate => _bufferPosController.stream;
  Stream<bool> get onBufferStateUpdate => _bufferStateController.stream;

  final Completer<int> _nativeSetup;

  FijkPlayer() : _nativeSetup = Completer() {
    _fpState = FijkState.IDLE;
    _epState = FijkState.ERROR;
    _doNativeSetup();
  }

  Future<void> _doNativeSetup() async {
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    _epState = FijkState.IDLE;

    print("native player id: $_playerId");

    _nativeEventSubscription =
        EventChannel('befovy.com/fijkplayer/event/' + _playerId.toString())
            .receiveBroadcastStream()
            .listen(eventListener, onError: errorListener);
    _nativeSetup.complete(_playerId);
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
      dateSourceType = type;
      dataSource = path;
      switch (dateSourceType) {
        case DateSourceType.network:
          dataSourceDescription = <String, dynamic>{'url': dataSource};
          break;
        case DateSourceType.asset:
          break;
        case DateSourceType.file:
          break;
      }
      _epState = FijkState.INITIALIZED;
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
    } else if (_epState == FijkState.PREPARED) {
      await _channel.invokeMethod("start");
      _epState = FijkState.STARTED;
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<int> pause() async {
    await _nativeSetup.future;
    _epState = FijkState.PAUSED;
    await _channel.invokeMethod("pause");
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

    _nativeEventSubscription.cancel();
    int pid = await _nativeSetup.future;
    return FijkPlugin.releasePlayer(pid);
  }

  void eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'state_change':
        int newState = map['new'];
        _fpState = FijkState.values[newState];
        if (_fpState == FijkState.ERROR) {
          _epState = FijkState.ERROR;
        }
        _playerStateController.add(_fpState);
        print(_fpState.toString() + " <= " + _epState.toString());
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
      default:
        break;
    }
  }

  void errorListener(Object obj) {
    final PlatformException e = obj;
    print("onError: $e");
  }
}
