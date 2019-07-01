import 'dart:async';
import 'package:flutter/services.dart';

import 'fijkplugin.dart';

enum DateSourceType { asset, network, file }

enum PlayerState {
  ///
  /// setDataSource  -> [INITIALIZED]
  /// reset          -> self
  /// release        -> [END]
  ///
  IDLE,

  ///
  /// prepareAsync   -> [ASYNC_PREPARING]
  /// reset          -> [IDLE]
  /// release        -> [END]
  INITIALIZED,

  ///
  ///        ...     -> [PREPARED]
  ///        ...     -> [ERROR]
  ///
  /// reset          -> created
  /// release        -> release
  ASYNC_PREPARING,

  ///
  /// start          -> started
  ///
  /// reset          -> created
  /// release        -> end
  PREPARED,

  /**
   *
   */
  STARTED,

  /**
   *
   */
  PAUSED,

  /**
   *
   */
  COMPLETED,

  /// stop        -> self
  ///
  STOPPED,

  /// reset        -> [IDLE]
  /// release      -> [END]
  ERROR,

  /// release      -> self
  END
}

class FijkPlayer {
  String dataSource;
  DateSourceType dateSourceType;

  PlayerState _fpState;
  PlayerState _epState;
  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  bool _buffering = false;
  Duration _bufferPos = Duration();

  // Duration _duration;
  // DurationRange _bufferd;

  final StreamController<PlayerState> _playerStateController =
      StreamController.broadcast();

  final StreamController<Duration> _bufferPosController =
      StreamController.broadcast();

  final StreamController<bool> _bufferStateController =
      StreamController.broadcast();

  PlayerState get state => _fpState;
  Duration get bufferPos => _bufferPos;
  bool get isBuffering => _buffering;

  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;
  Stream<Duration> get onBufferPosUpdate => _bufferPosController.stream;
  Stream<bool> get onBufferStateUpdate => _bufferStateController.stream;

  final Completer<int> _nativeSetup;

  FijkPlayer() : _nativeSetup = Completer() {
    _fpState = PlayerState.IDLE;
    _epState = PlayerState.ERROR;
    _doNativeSetup();
  }

  Future<void> _doNativeSetup() async {
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    _epState = PlayerState.IDLE;

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
    if (_epState == PlayerState.IDLE) {
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
      _epState = PlayerState.INITIALIZED;
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
    if (_epState == PlayerState.INITIALIZED) {
      _epState = PlayerState.PREPARED;
      await _channel.invokeMethod("prepareAsync");
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<int> start() async {
    await _nativeSetup.future;
    int ret = 0;
    if (_epState == PlayerState.INITIALIZED) {
      await _channel.invokeMethod("prepareAsync");
      await _channel.invokeMethod("start");
      _epState = PlayerState.STARTED;
    } else if (_epState == PlayerState.PREPARED) {
      await _channel.invokeMethod("start");
      _epState = PlayerState.STARTED;
    } else {
      ret = -1;
    }
    return Future.value(ret);
  }

  Future<int> pause() async {
    await _nativeSetup.future;
    _epState = PlayerState.PAUSED;
    await _channel.invokeMethod("pause");
    return Future.value(0);
  }

  Future<int> stop() async {
    await _nativeSetup.future;

    _epState = PlayerState.STOPPED;
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
        _fpState = PlayerState.values[newState];
        if (_fpState == PlayerState.ERROR) {
          _epState = PlayerState.ERROR;
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
