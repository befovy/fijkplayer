part of ui;

///a panel with volume control
FijkPanelWidgetBuilder fijkVolumePanelBuilder(
    {Color volumeColor,
    Color volumeBackgroundColor = Colors.black,
    Color backgroundColor = Colors.black38,
    AlignmentGeometry align = const Alignment(0, -0.8),
    double volumeWidth = 1.5}) {
  return (FijkPlayer player, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _DefaultVolumeFijkPanel(
        player: player,
        buildContext: context,
        viewSize: viewSize,
        align: align,
        backgroundColor: backgroundColor,
        volumeBackgroundColor: volumeBackgroundColor,
        volumeColor: volumeColor,
        volumeWidth: volumeWidth,
        texturePos: texturePos);
  };
}

class _DefaultVolumeFijkPanel extends StatefulWidget {
  final FijkPlayer player;
  final BuildContext buildContext;
  final Size viewSize;
  final Rect texturePos;
  final Color volumeColor;
  final Color volumeBackgroundColor;
  final Color backgroundColor;
  final AlignmentGeometry align;
  final double volumeWidth;

  const _DefaultVolumeFijkPanel(
      {Key key,
      @required this.player,
      this.buildContext,
      this.viewSize,
      this.texturePos,
      this.volumeColor,
      this.align,
      this.volumeWidth,
      this.volumeBackgroundColor,
      this.backgroundColor})
      : assert(player != null),
        super(key: key);

  @override
  _DefaultVolumeFijkPanelState createState() => _DefaultVolumeFijkPanelState();
}

class _DefaultVolumeFijkPanelState extends State<_DefaultVolumeFijkPanel> {
  double _volume;

  double get displayVolume=>_volumeController.value;

  bool display;

  Timer _timer;

  _VolumeController _volumeController;

  @override
  void initState() {
    super.initState();
    display = false;
    _volumeController=_VolumeController(1.0);
  }


  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  void hide() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 1000), () {
      setState(() {
        display = false;
      });
    });
  }


  Widget buildVolume() {
    IconData iconData;
    if (displayVolume <= 0) {
      iconData = Icons.volume_mute;
    } else if (displayVolume < 0.5) {
      iconData = Icons.volume_down;
    } else {
      iconData = Icons.volume_up;
    }

    return Card(
      color: widget.backgroundColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              iconData,
              color: Colors.white,
            ),
            Container(
              width: widget.viewSize.width * 0.25,
              height: widget.volumeWidth,
              margin: EdgeInsets.only(left: 8),
              child: LinearProgressIndicator(
                  value: displayVolume,
                  backgroundColor: widget.volumeBackgroundColor,
                  valueColor: AlwaysStoppedAnimation(
                      widget.volumeColor ?? Theme.of(context).primaryColor)),
            )
          ],
        ),
      ),
    );
  }

  void _down(double step){
    final newValue = displayVolume-step;
    setState(() {
      _volumeController.value=max(newValue,0);
      display = true;
    });
    hide();
  }

  void _up(double step){
    final newValue = displayVolume+step;
    setState(() {
      _volumeController.value=min(newValue,1);
      display = true;
    });
    hide();
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = widget.player.value.fullScreen
        ? Rect.fromLTWH(0, 0, widget.viewSize.width, widget.viewSize.height)
        : Rect.fromLTRB(
            max(0.0, widget.texturePos.left),
            max(0.0, widget.texturePos.top),
            min(widget.viewSize.width, widget.texturePos.right),
            min(widget.viewSize.height, widget.texturePos.bottom));
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        _volume += d.primaryDelta / widget.texturePos.height;
        if (_volume.abs() > 0.07) {
          _volume = min(max(_volume, -1), 1);
          if (_volume > 0) {
            _down(_volume);
          } else {
            _up(_volume.abs());
          }
          _volume = 0;
        }
      },
      onVerticalDragStart: (d) {
        setState(() {
          _volume = 0;
        });
      },
      child: Stack(
        children: [
          _DefaultFijkPanel(
              player: widget.player,
              volumeController: _volumeController,
              buildContext: widget.buildContext,
              viewSize: widget.viewSize,
              texturePos: widget.texturePos),
          Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: Align(
                alignment: widget.align,
                child: AnimatedOpacity(opacity: display ? 1 : 0,
                    duration: Duration(milliseconds: 200),child: buildVolume()),
              ),
            ),
          )
        ],
      ),
    );
  }
}
