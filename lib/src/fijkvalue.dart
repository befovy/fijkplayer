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

import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'fijkplayer.dart';

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

  /// whether if player should be displayed in full screen mode
  final bool fullScreen;

  final FijkException exception;

  /// A constructor requires all value.
  const FijkValue({
    @required this.prepared,
    @required this.completed,
    @required this.state,
    @required this.size,
    @required this.duration,
    @required this.fullScreen,
    @required this.exception,
  });

  /// Construct FijkValue with uninitialized value
  const FijkValue.uninitialized()
      : this(
          prepared: false,
          completed: false,
          state: FijkState.idle,
          size: null,
          duration: const Duration(),
          fullScreen: false,
          exception: null,
        );

  /// Return new FijkValue which combines the old value and the assigned new value
  FijkValue copyWith({
    bool prepared,
    bool completed,
    FijkState state,
    Size size,
    Duration duration,
    bool fullScreen,
    FijkException exception,
  }) {
    return FijkValue(
      prepared: prepared ?? this.prepared,
      completed: completed ?? this.completed,
      state: state ?? this.state,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      fullScreen: fullScreen ?? this.fullScreen,
      exception: exception ?? this.exception,
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
      prepared, completed, state, size, duration, fullScreen, exception);

  @override
  String toString() {
    return "prepared:$prepared, completed:$completed, state:$state, size:$size, "
        "duration:$duration, fullScreen:$fullScreen, exception:$exception";
  }
}

@immutable
class FijkException implements Exception {
  // idle 0
  static const int ok = 0;
  static const int asset404 = 404;

  static const int openFailed = 222;

  // initialized 1

  // asyncPreparing 2

  // prepared 3

  // started 4

  // paused 5

  // completed 6

  // stopped 7

  // error 8

  // end 9

  /// exception code
  final int code;

  /// short exception message
  final String msg;

  /// long exception message
  final String message;

  /// more detail about this exception
  final dynamic details;

  FijkException(code, [this.msg, this.message, this.details]) : code = code;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FijkException &&
              runtimeType == other.runtimeType &&
              code == other.code &&
              msg == other.msg &&
              message == other.message &&
              details == other.details;

  @override
  int get hashCode =>
      code.hashCode ^
      msg.hashCode ^
      message.hashCode ^
      details.hashCode;

  @override
  String toString() {
    return "FijkException($code, $msg, $message, $details)";
  }
}
