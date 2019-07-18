import 'package:fijkplayer/fijkpanel.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer/fijkview.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';

class VideoScreen extends StatefulWidget {
  final String url;

  VideoScreen({@required this.url});

  @override
  _VideoScreenState createState() => _VideoScreenState(url: url);
}

class _VideoScreenState extends State<VideoScreen> {
  final String url;
  final FijkPlayer player = FijkPlayer();

  _VideoScreenState({@required this.url});

  @override
  void initState() {
    super.initState();
    startPlay();
  }

  void startPlay() async {
    await player.setDataSource(DateSourceType.network, url);
    await player.start();

    player.onPlayerStateChanged.listen(ijkStateChange);
  }

  void ijkStateChange(FijkState state) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: FijkView(
          player: player,
          builder: FijkPanelBuilder(builder: defaultFijkPanelBuilder)),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
