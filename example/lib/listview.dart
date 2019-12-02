import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  static int listItemCount = 8;
  List<FijkPlayer> players;

  @override
  void initState() {
    super.initState();
    players = List();
    for (int i = 0; i < listItemCount; i++) {
      players.add(FijkPlayer());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "List View"),
      body: ListView.builder(
          itemCount: listItemCount,
          itemExtent: 240,
          itemBuilder: (BuildContext context, int index) {
            FijkPlayer p = players[index];
            FijkLog.i("build list item $index", tag: "list");
            p.setDataSource("asset:///assets/butterfly.mp4", autoPlay: true);
            return FijkView(
              player: p,
            );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (var p in players) {
      p.release();
    }
    players.clear();
  }
}
