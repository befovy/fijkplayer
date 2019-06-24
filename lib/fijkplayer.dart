import 'dart:async';

import 'package:flutter/services.dart';

import 'fijkplugin.dart';

enum DateSourceType { asset, network, file }

enum PlayerState {
  ///
  /// nativeSetup    -> created
  /// reset          ->
  /// release        -> end
  ///
  idle,

  ///
  /// setDataSource  -> initialized
  /// reset          -> self
  /// release        -> end
  ///
  created,

  ///
  /// prepareAsync   -> async_preparing
  /// reset          -> created
  /// release        -> end
  initialized,

  ///
  ///        ...     -> prepared
  ///        ...     -> error
  ///
  /// reset          -> created
  /// release        -> release
  async_preparing,

  ///
  /// start          -> started
  ///
  /// reset          -> created
  /// release        -> end
  prepared,

  /**
   *
   */
  started,

  /**
   *
   */
  paused,

  /**
   *
   */
  completed,

  /// strop        -> self
  ///
  stopped,

  /// reset        -> created
  /// release      -> end
  error,

  /// release      -> self
  end
}

// http://ivi.bupt.edu.cn/hls/cctv1.m3u8

class FijkPlayer {
  String dataSource;
  DateSourceType dateSourceType;

  PlayerState mkState;
  PlayerState epState;
  int _playerId;
  MethodChannel _channel;

  final Completer<int> nativeSetup;

  FijkPlayer() : nativeSetup = Completer() {
    mkState = PlayerState.idle;
    epState = PlayerState.idle;
    _nativeSetup();
  }

  Future<void> _nativeSetup() async {
    assert(mkState == PlayerState.idle);
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    mkState = PlayerState.created;
    print("native player id:" + _playerId.toString());

    EventChannel('befovy.com/fijkplayer/event/' + _playerId.toString())
        .receiveBroadcastStream()
        .listen(eventListener, onError: errorListener);
    nativeSetup.complete(_playerId);
  }


  Future<int> setupSurface() async {
    await nativeSetup.future;
    return _channel.invokeMethod("setupSurface");
  }

  Future<void> setDataSource(DateSourceType type, String path) async {
    await nativeSetup.future;
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

    return _channel.invokeMethod("setDateSource", dataSourceDescription);
  }


  Future<int> prepareAsync() async {

    // ckeck state
    await nativeSetup.future;
    await _channel.invokeMethod("prepareAsync");
    return Future.value(0);
  }

  Future<int> start() async {
    await nativeSetup.future;

    if (mkState == PlayerState.initialized) {
    } else if (mkState == PlayerState.async_preparing) {}

    await _channel.invokeMethod("start");
    return Future.value(0);
  }

  Future<int> pause() async {
        await _channel.invokeMethod("pause");
    return Future.value(0);
  }


  Future<int> stop() async {
    await _channel.invokeMethod("stop");
    return Future.value(0);
  }

  Future<int> reset() async {
    await _channel.invokeMethod("reset");
    return Future.value(0);
  }

  Future<void> release() async {
    int pid = await nativeSetup.future;
    return FijkPlugin.releasePlayer(pid);
  }


  void eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'initialized':
      default:
    }
  }

  void errorListener(Object obj) {
    final PlatformException e = obj;
  }
}
