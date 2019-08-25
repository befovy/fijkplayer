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
    player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      FijkException fe = e as FijkException;
      //setState(() {
      //  errorMsg = fe.message;
      //});
      print("setDataSource exception: $fe");
    }, test: (e) => e is FijkException);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: Container(
          child: FijkView(
        player: player,
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
