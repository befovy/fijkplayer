import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

import 'app_bar.dart';

class VideoScreen extends StatefulWidget {
  final String url;

  VideoScreen({@required this.url});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final FijkPlayer player = FijkPlayer();

  _VideoScreenState();

  @override
  void initState() {
    super.initState();
    player.setDataSource(widget.url, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: FijkAppBar.defaultSetting(title: "Video"),
        body: Container(
          alignment: Alignment.center,
          width: 200,
          height: 300,
          child: FijkView(
            player: player,
            aspectRatio: 1.5,
            alignment: Alignment.center
            // panelSize: FijkPanelSize.MatchView,
            // alignment: Alignment.center,
            // aspectRatio: 1,
            // width: 320,
            // height: 180,
            // builder: defaultFijkPanelBuilder,
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
