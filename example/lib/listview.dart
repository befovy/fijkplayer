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
  int _x = -1;

  @override
  void initState() {
    super.initState();
    if (widget.index == 0) {
      widget.notifier.addListener(scrollListener);
    }
    int mills = widget.index <= 3 ? 100 : 500;
    timer = Timer(Duration(milliseconds: mills), () async {
      player = FijkPlayer();
      await player.setLoop(0);
      await player.setDataSource("asset:///assets/butterfly.mp4");
      await player.prepareAsync();
      if (widget.index == 0 && _x == -1) {
        widget.notifier.value = 0;
      } else {
        widget.notifier.addListener(scrollListener);
      }
      setState(() {});
    });
  }

  void scrollListener() async {
    double pixels = widget.notifier.value;
    int x = (pixels / 200).ceil();
    _x = x;
    if (player != null && widget.index == x) {
      if (_start == false) {
        player.start();
        _start = true;
      }
    } else {
      if (player != null && player.isPlayable() && _start) {
        player.pause();
        _start = false;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(scrollListener);
    timer?.cancel();
    player?.release();
    player = null;
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
