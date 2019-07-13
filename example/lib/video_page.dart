import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer/fijkview.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';

class VideoWidget extends StatefulWidget {
  final String url;

  VideoWidget({@required this.url});

  @override
  _VideoWidgetState createState() => _VideoWidgetState(url: url);
}

class _VideoWidgetState extends State<VideoWidget> {
  final String url;

  final FijkPlayer player = FijkPlayer();

  _VideoWidgetState({@required this.url}) {
    setupVideo(url);
  }

  setupVideo(String url) async {
    await player.setDataSource(DateSourceType.network, url);
    await player.start();
  }

  @override
  Widget build(BuildContext context) {
    return FijkView(this.player);
  }
}

class VideoScreen extends StatelessWidget {
  final String url;

  VideoScreen({@required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: VideoWidget(url: this.url),
    );
  }
}
