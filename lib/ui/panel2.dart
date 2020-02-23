//MIT License
//
//Copyright (c) [2020] [Befovy]
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

part of fijkplayer;

FijkPanelWidgetBuilder panel2Builder(
    {Key key,
    final bool fill = false,
    final int duration = 3000,
    final bool doubleTap = true,
    final VoidCallback onBack}) {
  return (FijkPlayer player, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel2(
      key: key,
      player: player,
      onBack: onBack,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      doubleTap: doubleTap,
      hideDuration: duration,
    );
  };
}

class _FijkPanel2 extends StatefulWidget {
  final FijkPlayer player;
  final VoidCallback onBack;
  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final bool doubleTap;
  final int hideDuration;

  const _FijkPanel2(
      {Key key,
      @required this.player,
      this.fill,
      this.onBack,
      this.viewSize,
      this.hideDuration,
      this.doubleTap,
      this.texPos})
      : assert(player != null),
        assert(
            hideDuration != null && hideDuration > 0 && hideDuration < 10000),
        super(key: key);

  @override
  __FijkPanel2State createState() => __FijkPanel2State();
}

class __FijkPanel2State extends State<_FijkPanel2> {
  FijkPlayer get player => widget.player;

  Timer _hideTimer;
  bool _hideStuff = true;

  bool _prepared = false;
  bool _playing = false;
  bool _dragLeft;
  double _volume;
  double _brightness;

  double _seekPos = -1.0;
  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();

  StreamSubscription _currentPosSubs;
  StreamSubscription _bufferPosSubs;

  static const FijkSliderColors sliderColors =
      FijkSliderColors(cursorColor: Color.fromARGB(240, 252, 99, 10),
      playedColor: Color.fromARGB(200, 237, 86, 50),
      baselineColor: Color.fromARGB(100, 19, 19, 19),
      bufferedColor: Color.fromARGB(180, 200, 200, 200));

  @override
  void initState() {
    super.initState();

    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _currentPos = v;
        });
      } else {
        _currentPos = v;
      }
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _bufferPos = v;
        });
      } else {
        _bufferPos = v;
      }
    });

    player.addListener(_playerValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _hideTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  void _playerValueChanged() {
    FijkValue value = player.value;

    if (value.duration != _duration) {
      if (_hideStuff == false) {
        setState(() {
          _duration = value.duration;
        });
      } else {
        _duration = value.duration;
      }
    }
    bool playing = (value.state == FijkState.started);
    bool prepared = value.prepared;
    if (playing != _playing || prepared != _prepared) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
      });
    }
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: widget.hideDuration), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void onTapFun() {
    print("tap fun");
    if (_hideStuff == true) {
      _restartHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  void playOrPause() {
    if (player.isPlayable() || player.state == FijkState.asyncPreparing) {
      if (player.state == FijkState.started) {
        player.pause();
      } else {
        player.start();
      }
    } else {
      FijkLog.w("Invalid state ${player.state} ,can't perform play or pause");
    }
  }

  void onDoubleTapFun() {
    playOrPause();
  }

  void onVerticalDragStartFun(DragStartDetails d) {
    if (d.localPosition.dx > panelWidth() / 2) {
      // right, volume
      _dragLeft = false;
      FijkVolume.getVol().then((v) {
        _volume = v;
      });
    } else {
      // left, brightness
      _dragLeft = true;
      FijkPlugin.screenBrightness().then((v) {
        _brightness = v;
      });
    }
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    double delta = d.primaryDelta / panelHeight();
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragLeft != null && _dragLeft == false) {
      if (_volume != null) {
        _volume += delta;
        _volume = _volume.clamp(0.0, 1.0);
        FijkVolume.setVol(_volume);
      }
    } else if (_dragLeft != null && _dragLeft == true) {
      if (_brightness != null) {
        _brightness += delta;
        _brightness = _brightness.clamp(0.0, 1.0);
        FijkPlugin.setScreenBrightness(_brightness);
      }
    }
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    _volume = null;
    _brightness = null;
  }

  Widget buildPlayButton(BuildContext context, double height) {
    Icon icon = (player.state == FijkState.started)
        ? Icon(Icons.pause)
        : Icon(Icons.play_arrow);
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height,
      color: Color(0xFFFFFFFF),
      icon: icon,
      onPressed: playOrPause,
    );
  }

  Widget buildFullScreenButton(BuildContext context, double height) {
    Icon icon = player.value.fullScreen
        ? Icon(Icons.fullscreen_exit)
        : Icon(Icons.fullscreen);
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height,
      color: Color(0xFFFFFFFF),
      icon: icon,
      onPressed: () {
        player.value.fullScreen
            ? player.exitFullScreen()
            : player.enterFullScreen();
      },
    );
  }

  Widget buildTimeText(BuildContext context, double height) {
    String text =
        "${_duration2String(_currentPos)}" + "/${_duration2String(_duration)}";
    return Text(text, style: TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)));
  }

  Widget buildSlider(BuildContext context) {
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();

    return Padding(
        padding: EdgeInsets.only(left: 3),
        child: FijkSlider(
            colors: sliderColors,
            value: currentValue,
            cacheValue: _bufferPos.inMilliseconds.toDouble(),
            min: 0.0,
            max: _duration.inMilliseconds.toDouble(),
            onChanged: (v) {
              _restartHideTimer();
              setState(() {
                _seekPos = v;
              });
            },
            onChangeEnd: (v) {
              setState(() {
                player.seekTo(v.toInt());
                _currentPos = Duration(milliseconds: _seekPos.toInt());
                _seekPos = -1.0;
              });
            }));
  }

  Widget buildBottom(BuildContext context, double height) {
    if (_duration != null && _duration.inMilliseconds > 0) {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          buildTimeText(context, height),
          Expanded(child: buildSlider(context)),
          buildFullScreenButton(context, height),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          Expanded(child: Container()),
          buildFullScreenButton(context, height),
        ],
      );
    }
  }

  Widget buildPanel(BuildContext context) {
    double height = panelHeight();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: height > 200 ? 80 : height / 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x88000000), Color(0x00000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Color(0x00000000),
          ),
        ),
        Container(
          height: height > 80 ? 80 : height / 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x88000000), Color(0x00000000)],
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height > 80 ? 45 : height / 2,
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 5),
            child: buildBottom(context, height > 80 ? 40 : height / 2),
          ),
        )
      ],
    );
  }

  GestureDetector buildGestureDetector(BuildContext context) {
    return GestureDetector(
      onTap: onTapFun,
      onDoubleTap: widget.doubleTap ? onDoubleTapFun : null,
      onVerticalDragUpdate: onVerticalDragUpdateFun,
      onVerticalDragStart: onVerticalDragStartFun,
      onVerticalDragEnd: onVerticalDragEndFun,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: AnimatedOpacity(
          opacity: _hideStuff ? 0 : 0.8,
          duration: Duration(milliseconds: 300),
          child: buildPanel(context),
        ),
      ),
    );
  }

  Rect panelRect() {
    Rect rect = player.value.fullScreen || (true == widget.fill)
        ? Rect.fromLTWH(0, 0, widget.viewSize.width, widget.viewSize.height)
        : Rect.fromLTRB(
            max(0.0, widget.texPos.left),
            max(0.0, widget.texPos.top),
            min(widget.viewSize.width, widget.texPos.right),
            min(widget.viewSize.height, widget.texPos.bottom));
    return rect;
  }

  double panelHeight() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.height;
    } else {
      return min(widget.viewSize.height, widget.texPos.bottom) -
          max(0.0, widget.texPos.top);
    }
  }

  double panelWidth() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.width;
    } else {
      return min(widget.viewSize.width, widget.texPos.right) -
          max(0.0, widget.texPos.left);
    }
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = panelRect();
    return Positioned.fromRect(
        rect: rect, child: buildGestureDetector(context));
  }
}
