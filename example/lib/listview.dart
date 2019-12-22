import 'dart:async';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';

class ListItemPlayer extends StatefulWidget {
  final int index;
  final ValueNotifier<double> notifier;

  ListItemPlayer({@required this.index, @required this.notifier});

  @override
  _ListItemPlayerState createState() => _ListItemPlayerState();
}

class _ListItemPlayerState extends State<ListItemPlayer> {
  FijkPlayer player;
  Timer timer;
  bool _start = false;
  bool _finalize = false;
  bool _expectStart = false;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(scrollListener);
    int mills = widget.index <= 3 ? 100 : 500;
    timer = Timer(Duration(milliseconds: mills), () async {
      if (_finalize) return;
      player = FijkPlayer();
      if (_finalize) return;
      await player.setDataSource("asset:///assets/butterfly.mp4");
      if (_finalize) return;
      await player.prepareAsync();
      if (_finalize) return;
      scrollListener();
      if (_finalize) return;
      setState(() {});
    });
  }

  void scrollListener() {
    double pixels = widget.notifier.value;
    int x = (pixels / 200).ceil();
    if (player != null && widget.index == x) {
      _expectStart = true;
      player.removeListener(pauseListener);
      if (_start == false && player.isPlayable()) {
        FijkLog.i("start from scroll listener $player");
        player.start();
        _start = true;
      } else if (_start == false){
        FijkLog.i("add start listener $player");
        player.addListener(startListener);
      }
    } else if (player != null){
      _expectStart = false;
      player.removeListener(startListener);
      if (player.isPlayable() && _start) {
        FijkLog.i("pause from scroll listener $player");
        player.pause();
        _start = false;
      } else if (_start) {
        FijkLog.i("add pause listener $player");
        player.addListener(pauseListener);
      }
    }
  }

  void startListener() {
    FijkValue value = player.value;
    if (value.prepared && !_start && _expectStart) {
      _start = true;
      FijkLog.i("start from player listener $player");
      player.start();
    }
  }

  void pauseListener() {
    FijkValue value = player.value;
    if (value.prepared && _start && !_expectStart) {
      _start = false;
      FijkLog.i("pause from player listener $player");
      player.pause();
    }
  }

  void finalizer() async {
    _finalize = true;
    player?.removeListener(startListener);
    player?.removeListener(pauseListener);
    await player?.release();
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(scrollListener);
    timer?.cancel();
    finalizer();
  }

  @override
  Widget build(BuildContext context) {
    FijkFit fit = FijkFit(
      sizeFactor: 1.0,
      aspectRatio: 480 / 270,
      alignment: Alignment.center,
    );
    return Container(
        height: 200,
        child: Column(
          children: <Widget>[
            Text("${widget.index}", style: TextStyle(fontSize: 20)),
            Expanded(
              child: player != null
                  ? FijkView(
                      player: player,
                      fit: fit,
                      cover: AssetImage("assets/cover.png"),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF607D8B)),
                      child: Image.asset("assets/cover.png"),
                    ),
            )
          ],
        ));
  }
}

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ValueNotifier<double> notifier = ValueNotifier(-1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FijkAppBar.defaultSetting(title: "List View"),
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            notifier.value = notification.metrics.pixels;
            return true;
          },
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return ListItemPlayer(index: index, notifier: notifier);
            },
            cacheExtent: 1,
          ),
        ));
  }

}
