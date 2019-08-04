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
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'fijkplayer.dart';
import 'fijkview.dart';

/// Which area the panel should be rendered.
enum FijkPanelSize {
  /// same size as [FijkView]
  sameAsFijkView,

  /// same size as video(Texture) in[FijkView]
  sameAsVideo,
}

/// The signature of the [LayoutBuilder] builder function.
/// Must not return null.
typedef FijkPanelWidgetBuilder = Widget Function(
    FijkPlayer player, BuildContext context, BoxConstraints constraints);

/// Default builder generate default [FijkPanel] UI
Widget defaultFijkPanelBuilder(
    FijkPlayer player, BuildContext context, BoxConstraints constraints) {
  return DefaultFijkPanel(
      player: player, buildContext: context, boxConstraints: constraints);
}

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class DefaultFijkPanel extends StatefulWidget {
  final FijkPlayer player;
  final BuildContext buildContext;
  final BoxConstraints boxConstraints;

  const DefaultFijkPanel({
    @required this.player,
    this.buildContext,
    this.boxConstraints,
  });

  @override
  _DefaultFijkPanelState createState() => _DefaultFijkPanelState();
}

class _DefaultFijkPanelState extends State<DefaultFijkPanel> {
  FijkPlayer get player => widget.player;

  Duration _duration = Duration();
  Duration _currentPos = Duration();

  // Duration _bufferPos = Duration();
  bool _playing = false;
  bool _prepared = false;

  // bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription _currentPosSubs;

  //StreamSubscription _bufferPosSubs;
  //StreamSubscription _bufferingSubs;
  StreamSubscription _fijkStateSubs;

  Timer _hideTimer;
  bool _hideStuff = true;

  double _volume = 1.0;

  final barHeight = 40.0;

  @override
  void initState() {
    super.initState();

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    //_bufferPos = player.bufferPos;
    _prepared = player.state.index >= FijkState.PREPARED.index;
    _playing = player.state == FijkState.STARTED;
    // _buffering = player.isBuffering;

    player.addListener(_playerValueChanged);

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
      });
    });

    /*
    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });
    */

    /*
    _bufferingSubs = player.onBufferStateUpdate.listen((v) {
      setState(() {
        _buffering = v;
      });
    });
    */

    _fijkStateSubs = player.onPlayerStateChange.listen((v) {
      bool playing = v == FijkState.STARTED;
      bool prepared = v.index >= FijkState.PREPARED.index;
      if (playing != _playing || prepared != _prepared) {
        setState(() {
          _playing = playing;
          _prepared = prepared;
        });
      }
    });
  }

  void _playerValueChanged() {
    FijkValue value = player.value;
    if (value.duration != _duration) {
      setState(() {
        _duration = value.duration;
      });
    }
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _hideTimer?.cancel();

    player.removeListener(_playerValueChanged);
    _currentPosSubs?.cancel();
    //_bufferPosSubs.cancel();
    //_bufferingSubs.cancel();
    _fijkStateSubs.cancel();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _hideTimer?.cancel();
      _startHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: barHeight,
        color: Theme.of(context).dialogBackgroundColor,
        child: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off),
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                onPressed: () {
                  setState(() {
                    _volume = _volume > 0 ? 0.0 : 1.0;
                    player.setVolume(_volume);
                  });
                }),

            Padding(
              padding: EdgeInsets.only(right: 5.0, left: 5),
              child: Text(
                '${_duration2String(_currentPos)}',
                style: TextStyle(fontSize: 14.0),
              ),
            ),

            _duration.inMilliseconds == 0
                ? Expanded(
                    child: Center(),
                  )
                : Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 0, left: 0),
                      child: Slider(
                        value: currentValue,
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble(),
                        label: '$currentValue',
                        onChanged: (v) {
                          setState(() {
                            _seekPos = v;
                          });
                        },
                        onChangeEnd: (v) {
                          setState(() {
                            player.seekTo(v.toInt());
                            print("seek to $v");
                            _currentPos =
                                Duration(milliseconds: _seekPos.toInt());
                            _seekPos = -1;
                          });
                        },
                      ),
                    ),
                  ),

            // duration / position
            _duration.inMilliseconds == 0
                ? Container(child: const Text("LIVE"))
                : Padding(
                    padding: EdgeInsets.only(right: 5.0, left: 5),
                    child: Text(
                      '${_duration2String(_duration)}',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),

            IconButton(
              icon: Icon(widget.player.value.fullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen),
              padding: EdgeInsets.only(left: 10.0, right: 10.0),
//              color: Colors.transparent,
              onPressed: () {
                player.toggleFullScreen();
              },
            )
            //
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.boxConstraints,
      child: GestureDetector(
        onTap: _cancelAndRestartTimer,
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              Container(height: barHeight),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _cancelAndRestartTimer();
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: double.infinity,
                    width: double.infinity,
                    child: Center(
                        child: _prepared
                            ? AnimatedOpacity(
                                opacity: _hideStuff ? 0.0 : 0.7,
                                duration: Duration(milliseconds: 400),
                                child: IconButton(
                                    iconSize: barHeight * 2,
                                    icon: Icon(
                                        _playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white),
                                    padding: EdgeInsets.only(
                                        left: 10.0, right: 10.0),
                                    onPressed: _playOrPause))
                            : SizedBox(
                                width: barHeight * 1.5,
                                height: barHeight * 1.5,
                                child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white)),
                              )),
                  ),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }
}

class FijkPanelBuilder {
  const FijkPanelBuilder(
      {@required this.builder, this.panelSize = FijkPanelSize.sameAsFijkView})
      : assert(builder != null);

  final FijkPanelWidgetBuilder builder;
  final FijkPanelSize panelSize;

  Widget build(
      FijkPlayer player, BuildContext context, BoxConstraints constraints) {
    return builder(player, context, constraints);
  }
}
