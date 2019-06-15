import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer/fijkplugin.dart';
import 'package:flutter/material.dart';

class FijkView extends StatefulWidget {
  FijkView(this.player);

  final FijkPlayer player;

  @override
  createState() => _FijkViewState();
}

class _FijkViewState extends State<FijkView> {
  int _textureId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nativeSetup();
  }

  Future<void> _nativeSetup() async {
    final int vid = await widget.player.setupSurface();
    print("view setup, vid:" + vid.toString());
    setState(() {
      _textureId = vid;
    });
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.player.release();

    print("dispose");
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null
        ? Container()
        : Container(
            width: 350,
            height: 200,
            child: Texture(
              textureId: _textureId,
            ),
          );
  }
}


