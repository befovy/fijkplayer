import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

class FijkView extends StatefulWidget {
  FijkView(this.player);

  final FijkPlayer player;

  @override
  createState() => FijkViewState();
}

class FijkViewState extends State<FijkView> {
  int _textureId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }
}
