
part of fijkplayer;

FijkPanelWidgetBuilder fijkPanel3Builder(
    {Key key,
      final bool fill = false,
      final int duration = 4000,
      final bool doubleTap = true,
      final bool snapShot = false,
      final String title = '',
      final VoidCallback onTV,
      final VoidCallback onBack}) {
  return (FijkPlayer player, FijkData data, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel3(
      key: key,
      player: player,
      data: data,
      title: title,
      onBack: onBack,
      onTV: onTV,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      doubleTap: doubleTap,
      snapShot: snapShot,
      hideDuration: duration,
    );
  };
}

class _FijkPanel3 extends StatefulWidget {
  final FijkPlayer player;
  final FijkData data;
  final VoidCallback onBack;
  final String title;
  final VoidCallback onTV;
  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final bool doubleTap;
  final bool snapShot;
  final int hideDuration;

  const _FijkPanel3(
      {Key key,
        @required this.player,
        this.data,
        this.fill,
        this.onBack,
        this.onTV,
        this.viewSize,
        this.hideDuration,
        this.doubleTap,
        this.snapShot,
        this.texPos,
        this.title})
      : assert(player != null),
        assert(
        hideDuration != null && hideDuration > 0 && hideDuration < 10000),
        super(key: key);

  @override
  __FijkPanel3State createState() => __FijkPanel3State();
}

class __FijkPanel3State extends State<_FijkPanel3> {
  FijkPlayer get player => widget.player;

  Timer _hideTimer;
  bool _hideStuff = true;

  Timer _statelessTimer;
  bool _prepared = false;
  bool _playing = false;
  bool _dragLeft;
  double _volume;
  double _brightness;

  //手势滑动
  Duration _seekSpan = const Duration(seconds: 10); //滑动幅度
  Duration _gestureTempCurPos;
  double _gestureSeekStartX;
  double _gestureSeekEndX;

  double _seekPos = -1.0;
  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();

  StreamSubscription _currentPosSubs;
  StreamSubscription _bufferPosSubs;

  StreamController<double> _valController;

  // snapshot
  ImageProvider _imageProvider;
  Timer _snapshotTimer;

  // Is it needed to clear seek data in FijkData (widget.data)
  bool _needClearSeekData = true;

  static const FijkSliderColors sliderColors = FijkSliderColors(
      cursorColor: Colors.lightBlue,
      playedColor: Colors.lightBlueAccent,
      baselineColor: Colors.white38,
      bufferedColor: Color.fromARGB(180, 200, 200, 200));

  @override
  void initState() {
    super.initState();

    _valController = StreamController.broadcast();
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      if (_hideStuff == false) {
        if(_seekPos != -1.0){
          return;
        }
        setState(() {
          _currentPos = v;
        });
      } else {
        _currentPos = v;
      }
      if (_needClearSeekData) {
        widget.data.clearValue(FijkData._fijkViewPanelSeekto);
      }
      _needClearSeekData = false;
    });

    if (widget.data.contains(FijkData._fijkViewPanelSeekto)) {
      var pos = widget.data.getValue(FijkData._fijkViewPanelSeekto) as double;
      _currentPos = Duration(milliseconds: pos.toInt());
    }

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
    _valController?.close();
    _hideTimer?.cancel();
    _statelessTimer?.cancel();
    _snapshotTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  double dura2double(Duration d) {
    return d != null ? d.inMilliseconds.toDouble() : 0.0;
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
    if (playing != _playing ||
        prepared != _prepared ||
        value.state == FijkState.asyncPreparing) {
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

  void _restartStatelessHideTimer() {
    _statelessTimer?.cancel();
    _statelessTimer = Timer(const Duration(milliseconds: 2000), () {
      setState(() {});
    });
  }

  void onTapFun() {
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
        if (widget.data != null &&
            !widget.data.contains(FijkData._fijkViewPanelVolume)) {
          widget.data.setValue(FijkData._fijkViewPanelVolume, v);
        }
        setState(() {
          _volume = v;
          _valController.add(v);
        });
      });
    } else {
      // left, brightness
      _dragLeft = true;
      FijkPlugin.screenBrightness().then((v) {
        if (widget.data != null &&
            !widget.data.contains(FijkData._fijkViewPanelBrightness)) {
          widget.data.setValue(FijkData._fijkViewPanelBrightness, v);
        }
        setState(() {
          _brightness = v;
          _valController.add(v);
        });
      });
    }
    _restartStatelessHideTimer();
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    double delta = d.primaryDelta / panelHeight();
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragLeft != null && _dragLeft == false) {
      if (_volume != null) {
        _volume += delta;
        _volume = _volume.clamp(0.0, 1.0);
        FijkVolume.setVol(_volume);
        setState(() {
          _valController.add(_volume);
        });
      }
    } else if (_dragLeft != null && _dragLeft == true) {
      if (_brightness != null) {
        _brightness += delta;
        _brightness = _brightness.clamp(0.0, 1.0);
        FijkPlugin.setScreenBrightness(_brightness);
        setState(() {
          _valController.add(_brightness);
        });
      }
    }
    _restartStatelessHideTimer();
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    _volume = null;
    _brightness = null;
  }

  void onHorizontalDragStartFun(DragStartDetails e) {
    _gestureSeekStartX = e.localPosition.dx;
    _gestureTempCurPos = _currentPos;
  }

  void onHorizontalDragUpdateFun(DragUpdateDetails e) {
    _restartStatelessHideTimer();
    if (!_hideStuff) {
      _restartHideTimer();
    }
    _gestureSeekEndX = e.localPosition.dx;
    var dragValue = (_gestureSeekEndX - _gestureSeekStartX) / panelWidth();
    dragValue = dragValue * dura2double(_seekSpan);

    setState(() {
      _seekPos = max(
          0,
          min(dura2double(_duration),
              dura2double(_gestureTempCurPos) + dragValue));
      _currentPos = Duration(milliseconds: _seekPos.toInt());
    });
  }

  void onHorizontalDragEndFun(DragEndDetails e) {
    setState(() {
      _restartHideTimer();
      player.seekTo(_seekPos.toInt());
      _currentPos = Duration(milliseconds: _seekPos.toInt());
      widget.data.setValue(FijkData._fijkViewPanelSeekto, _seekPos);
      _needClearSeekData = true;
      _seekPos = -1.0;
    });
  }

  Widget buildPlayButton(BuildContext context, double height) {
    bool fullScreen = player.value.fullScreen;
    Icon icon = (player.state == FijkState.started)
        ? Icon(
      Icons.pause,
      color: Colors.white,
      size: fullScreen ? height * 0.6 : height * 0.6,
    )
        : Icon(
      Icons.play_arrow,
      color: Colors.white,
      size: fullScreen ? height * 0.6 : height * 0.6,
    );
    return Container(
      width: height * 0.8,
      height: height * 0.8,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: icon,
        onPressed: () {
          playOrPause();
          _restartHideTimer();
        },
      ),
    );
  }

  Widget buildFullScreenButton(BuildContext context, double height) {
    bool fullScreen = player.value.fullScreen;
    Icon icon = player.value.fullScreen
        ? Icon(
      Icons.fullscreen_exit,
      color: Colors.white,
      size: fullScreen ? height * 0.6 : height * 0.6,
    )
        : Icon(
      Icons.fullscreen,
      color: Colors.white,
      size: fullScreen ? height * 0.6 : height * 0.6,
    );
    return Container(
      width: height * 0.8,
      height: height * 0.8,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: icon,
        onPressed: () {
          player.value.fullScreen
              ? player.exitFullScreen()
              : player.enterFullScreen();
          _restartHideTimer();
        },
      ),
    );
  }

  Widget buildTimeText(BuildContext context, double height) {
    String current = _duration2String(_currentPos);
    String duration = _duration2String(_duration);

    return Row(
      children: [
        Text(current, style: TextStyle(fontSize: 12, color: Color(0xFFFFFFFF))),
        Text('/$duration',
            style: TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  Widget buildSlider(BuildContext context) {
    double duration = dura2double(_duration);

    double currentValue = _seekPos >= 0 ? _seekPos : dura2double(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);

    double bufferPos = dura2double(_bufferPos);
    bufferPos = bufferPos.clamp(0.0, duration);

    return Padding(
      padding: EdgeInsets.only(left: 3),
      child: CustomSlider(
        colors: sliderColors,
        value: currentValue,
        cacheValue: bufferPos,
        min: 0.0,
        max: duration,
        onChanged: (v) {
          _restartHideTimer();
          _restartStatelessHideTimer();
          setState(() {
            _seekPos = v;
            _currentPos = Duration(milliseconds: _seekPos.toInt());
          });
        },
        onChangeStart: (v) {
          setState(() {
            _seekPos = v;
            _currentPos = Duration(milliseconds: _seekPos.toInt());
          });
        },
        onChangeEnd: (v) {
          setState(() {
            _restartHideTimer();
            player.seekTo(v.toInt());
            _currentPos = Duration(milliseconds: _seekPos.toInt());
            widget.data.setValue(FijkData._fijkViewPanelSeekto, _seekPos);
            _needClearSeekData = true;
            _seekPos = -1.0;
          });
        },
      ),
    );
  }

  Widget buildTop(BuildContext context, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        widget.onBack != null ? buildBack(context, height) : Container(),
        widget.onTV != null ? buildTV(context, height) : Container(),
      ],
    );
  }

  Widget buildBottom(BuildContext context, double height) {
    if (_duration != null && _duration.inMilliseconds > 0) {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          buildTimeText(context, height),
          SizedBox(
            width: height * 0.2,
          ),
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

  void takeSnapshot() {
    player.takeSnapShot().then((v) {
      var provider = MemoryImage(v);
      precacheImage(provider, context).then((_) {
        setState(() {
          _imageProvider = provider;
        });
      });
      FijkLog.d("get snapshot succeed");
    }).catchError((e) {
      FijkLog.d("get snapshot failed");
    });
  }

  Widget buildPanel(BuildContext context) {
    double height = panelHeight();

    bool fullScreen = player.value.fullScreen;
    Widget centerWidget = Container(
      color: Color(0x00000000),
    );

    Widget centerChild = Container(
      color: Color(0x00000000),
    );

    if (fullScreen && widget.snapShot) {
      centerWidget = Row(
        children: <Widget>[
          Expanded(child: centerChild),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  padding: EdgeInsets.all(0),
                  color: Color(0xFFFFFFFF),
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    takeSnapshot();
                  },
                ),
              ],
            ),
          )
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          alignment: Alignment.topCenter,
          height: height > 200 ? 80 : height / 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x88000000), Color(0x00000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            height: height > 80 ? 45 : height / 2,
            child: buildTop(context, height > 80 ? 40 : height / 2),
          ),
        ),
        Expanded(
          child: centerWidget,
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
//            padding: EdgeInsets.only(left: 8, right: 8),
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
      onHorizontalDragStart: onHorizontalDragStartFun,
      onHorizontalDragUpdate: onHorizontalDragUpdateFun,
      onHorizontalDragEnd: onHorizontalDragEndFun,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: AnimatedOpacity(
          opacity: _hideStuff ? 0 : 1,
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
//            max(0.0, widget.texPos.left),
//            max(0.0, widget.texPos.top),
//            min(widget.viewSize.width, widget.texPos.right),
//            min(widget.viewSize.height, widget.texPos.bottom)
        0,
        0,
        widget.viewSize.width,
        widget.viewSize.height);
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

  Widget buildBack(BuildContext context, double height) {
    bool fullScreen = player.value.fullScreen;
    return Container(
      child: Row(
        children: [
          Container(
            width: height * 0.8,
            height: height * 0.8,
            child: CupertinoButton(
              //padding: EdgeInsets.only(left: 5),
              padding: EdgeInsets.zero,
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: fullScreen ? height * 0.5 : height * 0.5,
              ),
              onPressed: () {
                widget.onBack();
                _restartHideTimer();
              },
            ),
          ),
          widget.title.isNotEmpty
              ? Text(widget.title,
              style: TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)))
              : Container(),
        ],
      ),
    );
  }

  Widget buildTV(BuildContext context, double height) {
    bool fullScreen = player.value.fullScreen;
    return Container(
      width: height * 0.8,
      height: height * 0.8,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          widget.onTV();
          _restartHideTimer();
        },
        child: Icon(
          Icons.tv,
          color: Colors.white,
          size: fullScreen ? height * 0.5 : height * 0.5,
        ),
      ),
    );
  }

  Widget buildStateless() {
    if (_volume != null || _brightness != null || _seekPos != -1.0) {
      Widget toast = _volume == null
          ? _brightness == null
          ? customVideoProgressToast(_seekPos, dura2double(_duration))
          : defaultFijkBrightnessToast(_brightness, _valController.stream)
          : defaultFijkVolumeToast(_volume, _valController.stream);

      return IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1,
          duration: Duration(milliseconds: 500),
          child: toast,
        ),
      );
    } else if (player.state == FijkState.asyncPreparing) {
      return Container(
        alignment: Alignment.center,
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white)),
        ),
      );
    } else if (player.state == FijkState.error) {
      return Container(
        alignment: Alignment.center,
        child: Icon(
          Icons.error,
          size: 30,
          color: Color(0x99FFFFFF),
        ),
      );
    } else if (_imageProvider != null) {
      _snapshotTimer?.cancel();
      _snapshotTimer = Timer(Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _imageProvider = null;
          });
        }
      });
      return Center(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 3)),
            child:
            Image(height: 200, fit: BoxFit.contain, image: _imageProvider),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = panelRect();

    List ws = <Widget>[];

    if (_statelessTimer != null && _statelessTimer.isActive) {
      ws.add(buildStateless());
    } else if (player.state == FijkState.asyncPreparing) {
      ws.add(buildStateless());
    } else if (player.state == FijkState.error) {
      ws.add(buildStateless());
    } else if (_imageProvider != null) {
      ws.add(buildStateless());
    }
    ws.add(buildGestureDetector(context));

    return Positioned.fromRect(
      rect: rect,
      child: Stack(children: ws),
    );
  }
}
