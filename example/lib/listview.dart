import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';

class ListChildBuilderDelegate extends SliverChildBuilderDelegate {
  ListChildBuilderDelegate(builder)
      : super(
          builder,
        );

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    // print("first $firstIndex, last $lastIndex");
  }
}

class ListItemPlayer extends StatefulWidget {
  final int index;

  ListItemPlayer({@required this.index});

  @override
  _ListItemPlayerState createState() => _ListItemPlayerState();
}

class _ListItemPlayerState extends State<ListItemPlayer> {
  @override
  void initState() {
    super.initState();
    FijkLog.d("list initState ${widget.index}", tag: "list");
  }

  @override
  void deactivate() {
    super.deactivate();
    FijkLog.d("list deactivate ${widget.index}", tag: "list");
  }

  @override
  void dispose() {
    super.dispose();
    FijkLog.d("list dispose ${widget.index}", tag: "list");
  }

  @override
  Widget build(BuildContext context) {
    return Container(height: 260, child: Image.asset('assets/cover.png'));
  }
}

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  static int listItemCount = 15;
  final Map<int, FijkPlayer> _players = Map();

  @override
  void initState() {
    super.initState();
  }

  Widget listBuilder(BuildContext context, int index) {
    return ListItemPlayer(index: index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FijkAppBar.defaultSetting(title: "List View"),
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            //print("notification ${notification.metrics.pixels}");
            return false;
          },
          child: ListView.custom(
            childrenDelegate: ListChildBuilderDelegate(listBuilder),
            cacheExtent: 0.0,
          ),
        ));
  }


  @override
  void dispose() {
    super.dispose();
    _players.forEach((i, p) {
      p.release();
    });
    _players.clear();
  }
}
