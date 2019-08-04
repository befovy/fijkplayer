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

import 'package:fijkplayer/src/fijkpanel.dart';
import 'package:fijkplayer/src/fijkplugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'fijkpanel.dart';
import 'fijkplayer.dart';

/// [FijkView] is a widget that can display the video frame of [FijkPlayer].
///
/// Actually, it is a Container widget contains many children.
/// The most important is a Texture which display the read video frame.
class FijkView extends StatefulWidget {
  FijkView({
    @required this.player,
    this.width,
    this.height,
    this.aspectRatio,
    this.panelBuilder =
        const FijkPanelBuilder(builder: defaultFijkPanelBuilder),
    this.color = Colors.blueGrey,
    this.alignment = Alignment.center,
  }) : assert(player != null);

  /// The player that need display video by this [FijkView].
  /// Will be passed to [panelBuilder].
  final FijkPlayer player;

  /// builder to build panel Widget
  final FijkPanelBuilder panelBuilder;

  /// background color
  final Color color;

  /// [Alignment] for this [FijkView] Container
  final AlignmentGeometry alignment;

  /// [aspectRatio] controls inner video texture widget's aspect ratio.
  ///
  /// A [FijkView] has an important child widget which display the video frame.
  /// This important inner widget is a [Texture] in this version.
  /// Normally, we want the aspectRatio of [Texture] to be same
  /// as playback's real video frame's aspectRatio.
  /// It's also the default behaviour for [FijkView]
  /// or if aspectRatio is assigned null of negative value.
  ///
  /// If you want to change this default behaviour,
  /// just pass the aspectRatio you want.
  ///
  /// Addition: double.infinate is a special value.
  /// The aspect ratio of inner Texture will be same as FijkView's aspect ratio
  /// if you set double.infinate to attribute aspectRatio.
  final double aspectRatio;

  /// Nullable, width of [FijkView]
  /// If null, the weight will be as big as possible.
  final double width;

  /// Nullable, height of [FijkView].
  /// If null, the height will be as big as possible.
  final double height;

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
              return Stack(
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    child: AspectRatio(
                        aspectRatio: getAspectRatio(constraints),
                        child: Texture(textureId: _textureId)),
                  ),
                  widget.panelBuilder.build(widget.player, ctx, constraints)
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

  Widget buildTexture() {
    return _textureId > 0 ? Texture(textureId: _textureId) : Container();
  }

  // build Inter Texture and possible Panel
  Widget buildInterior() {
    if (widget.panelBuilder == null ||
        widget.panelBuilder.panelSize == FijkPanelSize.sameAsFijkView) {
      return Container(child: buildTexture());
    } else {
      return Stack(
        children: <Widget>[
          buildTexture(),
          LayoutBuilder(builder: (panelCtx, panelConstraints) {
            return widget.panelBuilder
                .build(widget.player, panelCtx, panelConstraints);
          })
        ],
      );
    }
  }

  // build child of External Container, maybe include Panel
  Widget buildExterior() {
    if (_fullScreen) return Container();

    return LayoutBuilder(builder: (ctx, constraints) {
      return widget.panelBuilder != null &&
              widget.panelBuilder.panelSize == FijkPanelSize.sameAsFijkView
          ? Stack(children: <Widget>[
              Container(
                alignment: widget.alignment,
                child: AspectRatio(
                    aspectRatio: getAspectRatio(constraints),
                    child: buildTexture()),
              ),
              widget.panelBuilder.build(widget.player, ctx, constraints)
            ])
          : AspectRatio(
              aspectRatio: getAspectRatio(constraints), child: buildInterior());
    });
  }

  // @override
  Widget oldBuild(BuildContext context) {
    return Container(
      color: Colors.green,
      width: 414,
      height: 807,
      alignment: widget.alignment,
      //child: buildExterior(),
      child: LayoutBuilder(builder: (ctx, constraints) {
        print("constraints $constraints");
        return AspectRatio(
          aspectRatio: getAspectRatio(constraints),
          child: Container(
            child: buildTexture(),
          ),
        );
      }),
    );
  }

  Size applyAspectRatio(BoxConstraints constraints) {
    assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);

    if (constraints.isTight) return constraints.smallest;

    double width = constraints.maxWidth;
    double height = width;

    // We default to picking the height based on the width, but if the width
    // would be infinite, that's not sensible so we try to infer the height
    // from the width.

    double aspectRatio = getAspectRatio(constraints);

    if (width.isFinite) {
      height = width / aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    // Similar to RenderImage, we iteratively attempt to fit within the given
    // constraints while maintaining the given aspect ratio. The order of
    // applying the constraints is also biased towards inferring the height
    // from the width.

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }

  @override
  Widget build(BuildContext context) {
    // return oldBuild(context);
    return LayoutBuilder(builder: (ctx, constraints) {
      // get child size

      Size childSize = applyAspectRatio(constraints);

      childSize = childSize * 1.5;
      // get offset
      Alignment resolvedAlignment = widget.alignment.resolve(null);
      Offset diff = constraints.biggest - childSize;
      Offset offset = resolvedAlignment.alongOffset(diff);

      Rect pos = Rect.fromLTWH(
          offset.dx, offset.dy, childSize.width, childSize.height);

      debugPrint("size ${constraints.biggest} childSize $childSize, pos $pos diff $diff");
      return Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.blueGrey,
          ),
          Positioned.fromRect(
            rect: pos,
            child: buildTexture(),
          )
        ],
      );
    });
  }
}
