import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';
// import 'custom_ui.dart';

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
    startPlay();
  }

  void startPlay() async {
    await player.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await player.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    await player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      print("setDataSource error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: Container(
        child: FijkVolumeWatcher(
            watcher: null,
            showToast: false,
            child: FijkView(
              player: player,
              panelBuilder: fijkPanel2Builder(),
              // panelBuilder: simplestUI,
              // panelBuilder: (FijkPlayer player, BuildContext context,
              //     Size viewSize, Rect texturePos) {
              //   return CustomFijkPanel(
              //       player: player,
              //       buildContext: context,
              //       viewSize: viewSize,
              //       texturePos: texturePos);
              // },
            )),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
