//
//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//


import 'package:fijkplayer/fijkpanel.dart';
import 'package:flutter/material.dart';

import 'fijkpanel.dart';
import 'fijkplayer.dart';

enum FijkPanelPos {
  MatchTexture,
  MatchFijkView,
}

class FijkView extends StatefulWidget {
  FijkView({@required this.player, this.builder, Color color})
      : color = color ?? Colors.blueGrey;

  final FijkPlayer player;
  final FijkPanelBuilder builder;
  final Color color;
  @override
  createState() => _FijkViewState();
}

class _FijkViewState extends State<FijkView> {
  int _textureId = -1;
  double _vWidth = -1;
  double _vHeight = -1;

  @override
  void initState() {
    super.initState();
    _nativeSetup();
    widget.player.addListener(_fijkValueListener);
  }

  Future<void> _nativeSetup() async {
    final int vid = await widget.player.setupSurface();
    print("view setup, vid:" + vid.toString());
    setState(() {
      _textureId = vid;
    });
  }

  void _fijkValueListener() {
    FijkValue value = widget.player.value;

    double width = _vWidth;
    double height = _vHeight;

    Size s = value.size;
    if (value.prepared) {
      print("prepared: $s");
      width = value.size.width;
      height = value.size.height;
    }
    print("width $width, height $height");

    if (width != _vWidth || height != _vHeight) {
      setState(() {
        _vWidth = width;
        _vHeight = height;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.player.release();
    print("FijkView dispose");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      child: LayoutBuilder(builder: (ctx, constraints) {
        Size s = (_vWidth > 0 && _vHeight > 0)
            ? constraints.constrainSizeAndAttemptToPreserveAspectRatio(
                Size(_vWidth.toDouble(), _vHeight.toDouble()))
            : Size(-1, -1);

        print("FijkView $constraints s: $s, tid $_textureId");

//        double.maxFinite

        return Stack(children: <Widget>[

//           (_vHeight > 0 && _vWidth > 0)  ?
//               Container(
//                 //constraints: constraints,
//                 width: constraints.maxWidth,
//          height: constraints.maxHeight,
//          child:FittedBox(
//
//            fit: BoxFit.none,
//            alignment: Alignment.center,
////            child:
////          Container(
//
////            width: constraints.maxWidth * 2,
////          height: constraints.maxHeight * 2,
//          child:
//          Container(
//            width: s.width,
//height: s.height,
////              aspectRatio: _vWidth / _vHeight,
//              child:
//            Texture(
//                textureId: _textureId,
//              ),
//            ),
//          ),
//          ):

          Center(
            child: Container(
              color: Colors.blue,
              width: s.width > 0.0 ? s.width : constraints.maxWidth,
              height: s.height > 0.0 ? s.height : constraints.maxHeight,
              child: _textureId > 0
                  ? Texture(
                      textureId: _textureId,
                    )
                  : null,
            ),
          ),
          widget.builder.build(widget.player, ctx, constraints),
        ]);
      }),
    );
  }
}
