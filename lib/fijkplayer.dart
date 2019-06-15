import 'dart:async';

import 'package:flutter/services.dart';

import 'fijkplugin.dart';

enum DateSourceType { asset, network, file }

enum PlayerState {
  idle,
  created,
  initialized,
  async_preparing,
  prepared,
  started,
  paused,
  completed,
  stopped,
  end
}

// http://ivi.bupt.edu.cn/hls/cctv1.m3u8

class FijkPlayer {
  String dataSource;
  DateSourceType dateSourceType;
  PlayerState playerState;
  int _playerId;
  MethodChannel _channel;

  final Completer<int> nativeSetup;

  FijkPlayer() : nativeSetup = Completer() {
    playerState = PlayerState.idle;
    _nativeSetup();
  }

  Future<void> _nativeSetup() async {
    assert(playerState == PlayerState.idle);
    _playerId = await FijkPlugin.createPlayer();
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());
    playerState = PlayerState.created;
    print("native player id:" + _playerId.toString());

    EventChannel('befovy.com/fijkplayer/event/' + _playerId.toString())
        .receiveBroadcastStream()
        .listen(eventListener, onError: errorListener);
    nativeSetup.complete(_playerId);
  }

  Future<void> release() async {
    int pid = await nativeSetup.future;
    return FijkPlugin.releasePlayer(pid);
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

  Future<int> start() async {
    if (playerState == PlayerState.initialized) {
    } else if (playerState == PlayerState.async_preparing) {}

    return Future.value(1);
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
