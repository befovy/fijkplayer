# fijkplayer ( Flutter 媒体播放器)

[![pub package](https://img.shields.io/pub/v/fijkplayer.svg)](https://pub.dartlang.org/packages/fijkplayer) &nbsp; &nbsp;
[![Build Status](https://travis-ci.org/befovy/fijkplayer.svg?branch=master)](https://travis-ci.org/befovy/fijkplayer) &nbsp; &nbsp;

您的支持是我们开发的动力。 欢迎Star，欢迎PR~。

一款支持 android 和 iOS 的 Flutter 媒体播放器插件，由 [ijkplayer](https://github.com/befovy/ijkplayer) 底层驱动。通过纹理接入 Flutter 中。


*README 其他语言版本: [English](README.en.md), [简体中文](README.zh-cn.md).*


## 安装

在 flutter 项目配置文件 `pubspec.yaml` 中加入 `fijkplayer` 依赖。

```yaml
dependencies:
  fijkplayer: ^0.0.6
```

## 基础用法


```dart
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

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
        appBar: AppBar(title: Text("Fijkplayer Example")),
        body: Container(
          alignment: Alignment.center,
          child: FijkView(
            player: player,
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

```

## 示例

demo app 在 example 文件夹中。

```
cd example && flutter run
```

iOS screenshots
<div>
<img src="https://user-images.githubusercontent.com/51129600/61178868-abefcc00-a629-11e9-851f-f4b2ab0028fb.jpeg" height="300px" alt="ios_input" >
&nbsp;	&nbsp;	&nbsp;	
<img src="https://user-images.githubusercontent.com/51129600/61178869-abefcc00-a629-11e9-8b15-872d8cd207b9.jpeg" height="300px" alt="ios_video" >
</div>

android screenshots

<div>
<img src="https://user-images.githubusercontent.com/51129600/61178866-ab573580-a629-11e9-8019-77a400998531.jpeg" height="300px" alt="android_home" >
&nbsp;	&nbsp;	&nbsp;	
<img src="https://user-images.githubusercontent.com/51129600/61178867-ab573580-a629-11e9-8829-8a37efb39d7d.jpeg" height="300px" alt="android_video" >
</div>

## ijkplayer 后端

项目中使用 ijkplayer 作为后端播放内核，在 [Bilibili/ijkplayer](https://github.com/Bilibili/ijkplayer) 的基础上进行修改而来 [befovy/ijkplayer](https://github.com/befovy/ijkplayer) ，主要增加对于 Flutter 纹理接入的支持。
修改后在 CocoaPods 和 http://bintray.com 进行了发布。

单独引入方式如下
``
# support arm64 armv7 armv7s x86_64 i386
pod 'FIJKPlayer'
```

```gradle
dependencies {
    // fijkplayer-full include the java lib and native shared libs for armv5 armv7 arm64 x86 x86_64
    implementation 'com.befovy.fijkplayer:fijkplayer-full:0.3.2'
}
```


## iOS 注意事项

Flutter 纹理接入的方式目前在 iOS 模拟器上不能工作，故视频播放器的图像只能在真机上显示出来，详情可查看 [flutter/issues/14647](https://github.com/flutter/flutter/issues/14647)。
当然如果不关注视频画面，比如播放音乐，在模拟器上调试是没问题的。
