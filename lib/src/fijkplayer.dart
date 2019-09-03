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
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'fijkoption.dart';
import 'fijkplugin.dart';
import 'fijkvalue.dart';

/// FijkPlayer present as a playback. It interacts with native object.
///
/// FijkPlayer invoke native method and receive native event.
class FijkPlayer extends ChangeNotifier implements ValueListenable<FijkValue> {
  static Map<int, FijkPlayer> _allInstance = HashMap();
  String _dataSource;

  int _playerId;
  MethodChannel _channel;
  StreamSubscription<dynamic> _nativeEventSubscription;

  StreamSubscription _looperSub;

  bool _startAfterSetup = false;

  FijkValue _value;

  static Iterable<FijkPlayer> get allInstance => _allInstance.values;

  /// return the player unique id.
  int get id => _playerId;

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
    _doNativeSetup();
  }

  Future<void> _startFromAnyState() async {
    await _nativeSetup.future;

    if (state == FijkState.error || state == FijkState.stopped) {
      await reset();
    }
    if (state == FijkState.idle) {
      await setDataSource(_dataSource);
    }
    if (state == FijkState.initialized) {
      await prepareAsync();
    }
    if (state == FijkState.asyncPreparing ||
        state == FijkState.prepared ||
        state == FijkState.completed ||
        state == FijkState.paused) {
      await start();
    }
  }

  Future<void> _doNativeSetup() async {
    _playerId = -1;
    _playerId = await FijkPlugin.createPlayer();
    _allInstance[_playerId] = this;
    _channel = MethodChannel('befovy.com/fijkplayer/' + _playerId.toString());

    _nativeEventSubscription =
        EventChannel('befovy.com/fijkplayer/event/' + _playerId.toString())
            .receiveBroadcastStream()
            .listen(_eventListener, onError: _errorListener);
    _nativeSetup.complete(_playerId);

    if (_startAfterSetup) {
      await _startFromAnyState();
    }

    _looperSub = Stream.periodic(const Duration(milliseconds: 200), (v) => v)
        .listen(_looper);
    _looperSub.pause();
  }

  /// Check if player is playable
  ///
  /// Only the four state [FijkState.prepared] \ [FijkState.started] \
  /// [FijkState.paused] \ [FijkState.completed] are playable
  bool isPlayable() {
    FijkState current = value.state;
    return FijkState.prepared == current ||
        FijkState.started == current ||
        FijkState.paused == current ||
        FijkState.completed == current;
  }

  /// set option
  /// [value] must be int or String
  Future<void> setOption(int category, String key, dynamic value) async {
    await _nativeSetup.future;
    if (value is String)
      return _channel.invokeMethod("setOption",
          <String, dynamic>{"cat": category, "key": key, "str": value});
    else if (value is int)
      return _channel.invokeMethod("setOption",
          <String, dynamic>{"cat": category, "key": key, "long": value});
    else
      return Future.error(
          ArgumentError.value(value, "value", "Must be int or String"));
  }

  Future<void> applyOptions(FijkOption fijkOption) async {
    await _nativeSetup.future;
    return _channel.invokeMethod("applyOptions", fijkOption.data);
  }

  Future<int> setupSurface() async {
    await _nativeSetup.future;
    return _channel.invokeMethod("setupSurface");
  }

  /// Set data source for this player
  ///
  /// [path] must be a valid uri, otherwise this method return ArgumentError
  ///
  /// set assets as data source
  /// first add assets in app's pubspec.yml
  ///   assets:
  ///     - assets/butterfly.mp4
  ///
  /// pass "asset:///assets/butterfly.mp4" to [path]
  /// scheme is `asset`, `://` is scheme's separator， `/` is path's separator.
  Future<void> setDataSource(
    String path, {
    bool autoPlay = false,
  }) async {
    if (path == null || path.length == 0 || Uri.tryParse(path) == null) {
      return Future.error(
          ArgumentError.value(path, "path must be a valid url"));
    }
    await _nativeSetup.future;
    if (state == FijkState.idle || state == FijkState.initialized) {
      try {
        await _channel
            .invokeMethod("setDateSource", <String, dynamic>{'url': path});
      } on PlatformException catch (e) {
        return _errorListener(e);
      }
      if (autoPlay == true) {
        await start();
      }
    } else {
      return Future.error(StateError("setDataSource on invalid state $state"));
    }
  }

  Future<void> prepareAsync() async {
    await _nativeSetup.future;
    if (state == FijkState.initialized) {
      await _channel.invokeMethod("prepareAsync");
    } else {
      return Future.error(StateError("prepareAsync on invalid state $state"));
    }
  }

  Future<void> setVolume(double volume) async {
    await _nativeSetup.future;
    return _channel
        .invokeMethod("setVolume", <String, dynamic>{"volume": volume});
  }

  /// enter full screen mode， set [FijkValue.fullScreen] to true
  void enterFullScreen() {
    _setValue(value.copyWith(fullScreen: true));
  }

  /// exit full screen mode, set [FijkValue.fullScreen] to false
  void exitFullScreen() {
    _setValue(value.copyWith(fullScreen: false));
  }

  Future<void> start() async {
    await _nativeSetup.future;
    if (state == FijkState.initialized) {
      await _channel.invokeMethod("prepareAsync");
      await _channel.invokeMethod("start");
    } else if (state == FijkState.asyncPreparing ||
        state == FijkState.prepared ||
        state == FijkState.paused ||
        value.state == FijkState.completed) {
      await _channel.invokeMethod("start");
    } else {
      Future.error(StateError("call start on invalid state $state"));
    }
  }

  Future<void> pause() async {
    await _nativeSetup.future;
    if (isPlayable())
      await _channel.invokeMethod("pause");
    else {
      Future.error(StateError("call pause on invalid state $state"));
    }
  }

  Future<void> stop() async {
    await _nativeSetup.future;
    if (state == FijkState.end ||
        state == FijkState.idle ||
        state == FijkState.initialized)
      Future.error(StateError("call stop on invalid state $state"));
    else
      await _channel.invokeMethod("stop");
  }

  Future<void> reset() async {
    await _nativeSetup.future;
    if (state == FijkState.end)
      Future.error(StateError("call reset on invalid state $state"));
    else {
      await _channel.invokeMethod("reset");
      _setValue(
          FijkValue.uninitialized().copyWith(fullScreen: value.fullScreen));
    }
  }

  Future<void> seekTo(int msec) async {
    await _nativeSetup.future;
    if (msec == null || msec < 0)
      return Future.error(
          ArgumentError.value(msec, "speed must be not null and >= 0"));
    if (!isPlayable())
      Future.error(StateError("Non playable state $state"));
    else
      _channel.invokeMethod("seekTo", <String, dynamic>{"msec": msec});
  }

  /// Release native player. Release memory and resource
  Future<void> release() async {
    await _nativeSetup.future;
    if (isPlayable()) await this.stop();
    _setValue(value.copyWith(state: FijkState.end));
    await _looperSub?.cancel();
    _looperSub = null;
    await _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;
    _allInstance.remove(_playerId);
    await FijkPlugin.releasePlayer(_playerId);
  }

  /// Set player loop count
  ///
  /// [loopCount] must not null and greater than or equal to 0.
  /// Default loopCount of player is 1, which also means no loop.
  /// A positive value of [loopCount] means special repeat times.
  /// If [loopCount] is 0, is means infinite repeat.
  Future<void> setLoop(int loopCount) async {
    await _nativeSetup.future;
    if (loopCount == null || loopCount < 0)
      return Future.error(ArgumentError.value(
          loopCount, "loopCount must not be null and >= 0"));
    return _channel
        .invokeMethod("setLoop", <String, dynamic>{"loop": loopCount});
  }

  /// Set playback speed
  ///
  /// [speed] must not null and greater than 0.
  /// Default speed is 1
  Future<void> setSpeed(double speed) async {
    await _nativeSetup.future;
    if (speed == null || speed <= 0)
      return Future.error(ArgumentError.value(
          speed, "speed must be not null and greater than 0"));
    return _channel.invokeMethod("setSpeed", <String, dynamic>{"speed": speed});
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
        int duration = map['duration'] ?? 0;
        Duration dur = Duration(milliseconds: duration);
        _setValue(value.copyWith(duration: dur, prepared: true));
        break;
      case 'state_change':
        int newStateId = map['new'];
        int _oldState = map['old'];
        FijkState fpState = FijkState.values[newStateId];
        FijkState oldState =
            (_oldState >= 0 && _oldState < FijkState.values.length)
                ? FijkState.values[_oldState]
                : state;

        if (fpState != oldState) {
          debugPrint("state_change: new: $fpState <= old: $oldState");

          if (fpState == FijkState.started) {
            _looperSub.resume();
          } else {
            if (!_looperSub.isPaused) _looperSub.pause();
          }
          FijkException fijkException =
              (fpState != FijkState.error) ? FijkException.noException : null;
          if (newStateId == FijkState.prepared.index) {
            _setValue(value.copyWith(
                prepared: true, state: fpState, exception: fijkException));
          } else if (newStateId < FijkState.prepared.index) {
            _setValue(value.copyWith(
                prepared: false, state: fpState, exception: fijkException));
          } else {
            _setValue(value.copyWith(state: fpState, exception: fijkException));
          }
        }
        break;
      case 'rendering_start':
        String type = map['type'] ?? "none";
        if (type == "video") {
          _setValue(value.copyWith(videoRenderStart: true));
          debugPrint("video rendering started");
        } else if (type == "audio") {
          _setValue(value.copyWith(audioRenderStart: true));
          debugPrint("audio rendering started");
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

  void _errorListener(Object obj) {
    final PlatformException e = obj;
    FijkException exception = FijkException.fromPlatformException(e);
    debugPrint("errorListerner: $e, $exception");
    _setValue(value.copyWith(exception: exception));
  }
}
