import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer_example/my_sliver_child_builder_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "List View"),
      body: ListView.custom(
        childrenDelegate: MySliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (!_players.containsKey(index)) {
              _players[index] = FijkPlayer();
              _players[index].setDataSource("asset:///assets/butterfly.mp4");
            }
            FijkLog.i("build list item $index", tag: "list");
            return Column(
              children: <Widget>[
                Container(
                  height: 240.0,
                  child: FijkView(
                    player: _players[index],
                  ),
                ),
                SizedBox(height: 12.0)
              ],
            );
          },
          childCount: listItemCount,
          onItemVisibilityState: setVideoVisibilityState,
        ),
        //设置cacheExtent 为0.0 不然获取到的显示隐藏的index不准确
        cacheExtent: 0.0,
      ),
    );
  }

  void setVideoVisibilityState(List<int> exposure, List<int> hidden) {
    exposure.forEach((index) {
      //显示的indexs
      if (_players[index]?.state == FijkState.idle) {
        _players[index]?.setDataSource("asset:///assets/butterfly.mp4");
      }
    });
    hidden.forEach((index) async {
      //隐藏的indexs
       _players[index]?.stop();
       _players[index]?.reset();
    });
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
