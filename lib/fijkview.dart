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
import 'package:fijkplayer/fijkplugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fijkpanel.dart';
import 'fijkplayer.dart';

class FijkView extends StatefulWidget {
  FijkView(
      {@required this.player,
      this.builder,
      Color color,
      AlignmentGeometry alignment,
      double aspectRatio})
      : color = color ?? Colors.blueGrey,
        alignment = alignment ?? Alignment.center,
        aspectRatio = aspectRatio ?? -1;

  final FijkPlayer player;

  /// build FijkPanel
  final FijkPanelBuilder builder;

  /// background color
  final Color color;

  final AlignmentGeometry alignment;

  /// A null or negative value  video aspect
  /// double.infinate lead to fill parent widget.
  final double aspectRatio;

  @override
  createState() => _FijkViewState();
}

class _FijkViewState extends State<FijkView> {
  int _textureId = -1;
  double _vWidth = -1;
  double _vHeight = -1;
  bool _fullScreen = false;

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

  void _fijkValueListener() async {
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

    if (value.fullScreen && !_fullScreen) {
      _fullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_fullScreen && !value.fullScreen) {
      Navigator.of(context).pop();
      _fullScreen = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.player.release();
    print("FijkView dispose");
  }

  double getAspectRatio(BoxConstraints constraints) {
    double ar = widget.aspectRatio;
    if (ar == null || ar < 0) {
      ar = _vWidth / _vHeight;
    } else if (ar == double.infinity) {
      ar = constraints.maxWidth / constraints.maxHeight;
    }
    return ar;
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context, Animation<double> animation) {
    
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return Scaffold(
            resizeToAvoidBottomInset: false,
            body: LayoutBuilder(builder: (ctx, constraints) {
              print("value:${widget.player.value}");

              return Stack(
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    color: Colors.blueGrey,
                    child: AspectRatio(
                        aspectRatio: getAspectRatio(constraints),
                        child: Texture(textureId: _textureId)),
                  ),
                  widget.builder.build(widget.player, ctx, constraints)
                ],
              );
            }));
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation) {
    return _defaultRoutePageBuilder(context, animation);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIOverlays([]);
    await FijkPlugin.setOrientationLandscape(context: context);
    await Navigator.of(context).push(route);
    _fullScreen = false;
    if (widget.player.value.fullScreen) {
      widget.player.toggleFullScreen();
    }
    await SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    await FijkPlugin.setOrientationPortrait(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fullScreen ? Colors.black : widget.color,
      alignment: _fullScreen ? Alignment.center : widget.alignment,
      child: (!_fullScreen && _vHeight > 0 && _vWidth > 0)
          ? LayoutBuilder(builder: (ctx, constraints) {
              return AspectRatio(
                aspectRatio: getAspectRatio(constraints),
                child: Stack(
                  children: <Widget>[
                    _textureId > 0
                        ? Texture(textureId: _textureId)
                        : Container(),
                    LayoutBuilder(builder: (panelCtx, panelConstraints) {
                      return widget.builder
                          .build(widget.player, panelCtx, panelConstraints);
                    }),
                  ],
                ),
              );
            })
          : Container(),
    );
  }
}
