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

/// The signature of the [LayoutBuilder] builder function.
typedef FijkPanelWidgetBuilder = Widget Function(
    FijkPlayer player, BuildContext context, BoxConstraints constraints);

/// default create IJK Controller UI
Widget defaultFijkPanelBuilder(
    FijkPlayer player, BuildContext context, BoxConstraints constraints) {
  return DefaultFijkPanel(
      player: player, buildContext: context, boxConstraints: constraints);
}

String duration2String(Duration duration) {
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
  Duration _bufferPos = Duration();
  bool _playing = false;
  bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription _currentPosSubs;
  StreamSubscription _bufferPosSubs;
  StreamSubscription _bufferingSubs;
  StreamSubscription _fijkStateSubs;
  
  Timer _hideTimer;
  bool _hideStuff = true;

  double _volume = 1.0;

  final barHeight = 40.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    player.addListener(_playerValueChanged);

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
      });
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });

    _bufferingSubs = player.onBufferStateUpdate.listen((v) {
      setState(() {
        _buffering = v;
      });
    });

    _fijkStateSubs = player.onPlayerStateChanged.listen((v) {
      bool playing = v == FijkState.STARTED;
      if (playing != _playing) {
        setState(() {
          _playing = playing;
          print("_set playing $_playing");
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
    print("_playOrPause $_playing");
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  @override
  void dispose() {
    super.dispose();

    player.removeListener(_playerValueChanged);
    _currentPosSubs.cancel();
    _bufferPosSubs.cancel();
    _bufferingSubs.cancel();
    _fijkStateSubs.cancel();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 8), () {
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
    print("_cancelAndRestartTimer $_hideStuff");
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  Widget _buildPosition(Color iconColor) {
    final position = _currentPos ?? Duration.zero;
    final duration = _duration ?? Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 10.0),
      child: Text(
        '${duration2String(position)} / ${duration2String(duration)}',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.button.color;

    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inSeconds.toDouble();

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: barHeight,
        color: Theme.of(context).dialogBackgroundColor,
        child: Row(
          children: <Widget>[
            // mute or not muter
            GestureDetector(
              onTap: _playOrPause,
              child: Container(
                height: barHeight,
                color: Colors.transparent,
                padding: EdgeInsets.only(left: 12.0, right: 12.0),
                child: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(right: 5.0, left: 5),
              child: Text(
                '${duration2String(_currentPos)}',
                style: TextStyle(
                  fontSize: 14.0,
                ),
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
                        max: _duration.inSeconds.toDouble(),
                        label: '$currentValue',
                        //divisions: _duration.inSeconds,
                        onChanged: (e) {
                          setState(() {
                            _seekPos = e;
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
                      '${duration2String(_duration)}',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),

            // play or pause
            GestureDetector(
              onTap: _playOrPause,
              child: Container(
                height: barHeight,
                color: Colors.transparent,
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                child: Icon(_playing ? Icons.fullscreen : Icons.fullscreen_exit),
              ),
            ),

            //
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [
      IconButton(
        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
        onPressed: () {
          _playing ? player.pause() : player.start();
        },
      ),
    ];

    String times = _duration.inMilliseconds > 0
        ? duration2String(_currentPos) + "/" + duration2String(_duration)
        : duration2String(_currentPos);

    rows.add(Text(
      times,
      textWidthBasis: TextWidthBasis.longestLine,
    ));

    if (_duration.inMilliseconds > 0) {
      double currentValue =
          _seekPos > 0 ? _seekPos : _currentPos.inSeconds.toDouble();

      rows.add(Slider(
        value: currentValue,
        min: 0.0,
        max: _duration.inSeconds.toDouble(),
        label: '$currentValue',
        //divisions: _duration.inSeconds,
        onChanged: (e) {
          setState(() {
            _seekPos = e;
          });
        },
      ));
    }

    return Container(
      constraints: widget.boxConstraints,
      child: GestureDetector(
        onTap: _cancelAndRestartTimer,
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
               Expanded(
                child:  GestureDetector(
                  onTap: (){
                    print("SDFdsf");
                    _cancelAndRestartTimer();
                  },
                  child: Container(
                    color: Colors.transparent,
                  height: double.infinity,
                    width: double.infinity,
                    child:
                    AnimatedOpacity(
                      opacity: _hideStuff ? 0.0 : 0.7,
                      duration: Duration(milliseconds: 400),
                    child:
                    Center(
                      child:  GestureDetector(
                        onTap: _playOrPause,
                        child: Container(

                          child: Icon(_playing  ? Icons.pause : Icons.play_arrow, size: barHeight * 2,
                          color: Colors.white,),
                        ),
                      ),),
                    ),
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
  const FijkPanelBuilder({
    Key key,
    @required this.builder,
  }) : assert(builder != null);

  /// Called at layout time to construct the widget tree. The builder must not
  /// return null.
  final FijkPanelWidgetBuilder builder;

  Widget build(FijkPlayer player, BuildContext buildContext,
      BoxConstraints boxConstraints) {
    return builder(player, buildContext, boxConstraints);
  }
}
