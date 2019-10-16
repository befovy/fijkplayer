# fijkplayer ( Flutter 媒体播放器)

### [English Language](README.en.md)

**[程序员帮老丈人卖石榴](https://www.yuque.com/befovy/share/pomegranate)**


[![pub package](https://img.shields.io/pub/v/fijkplayer.svg)](https://pub.dartlang.org/packages/fijkplayer) &nbsp; &nbsp;
[![Build Status](https://travis-ci.org/befovy/fijkplayer.svg?branch=master)](https://travis-ci.org/befovy/fijkplayer) &nbsp; &nbsp;

您的支持是我们开发的动力。 欢迎Star，欢迎PR~。

一款支持 android 和 iOS 的 Flutter 媒体播放器插件，由 [ijkplayer](https://github.com/befovy/ijkplayer) 底层驱动。通过纹理接入 Flutter 中。


## 文档

* 开发文档  https://fijkplayer.befovy.com 包含快速开始、使用指南、fijkplayer 中的概念理解
* dart api 文档  https://pub.dev/documentation/fijkplayer/ 中有详细的接口文档和参数说明
* Release Notes https://github.com/befovy/fijkplayer/releases 和 [CHANGELOG.md](./CHANGELOG.md) 包含每次的发版记录和说明

## 安装

在 flutter 项目配置文件 `pubspec.yaml` 中加入 `fijkplayer` 依赖。

```yaml
dependencies:
  fijkplayer: ^0.1.9
```

使用未发布版本
```yaml
dependencies:
  fijkplayer:
    git:
      url: https://github.com/befovy/fijkplayer.git
      ref: develop # 换成别的分支名或者 tag 或者 commit hash
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

## 贡献者列表

感谢这些 [超级可爱的贡献者们](./CONTRIBUTORS.md) ([emoji key](https://allcontributors.org/docs/en/emoji-key))

此项目遵循 [all-contributors](https://github.com/all-contributors/all-contributors) 规范，欢迎任何形式的贡献参与


## iOS 注意事项

Flutter 纹理接入的方式目前在 iOS 模拟器上不能工作，故视频播放器的图像只能在真机上显示出来，详情可查看 [flutter/issues/14647](https://github.com/flutter/flutter/issues/14647)。
当然如果不关注视频画面，比如播放音乐，在模拟器上调试是没问题的。


## QQ 交流群

扫码加入 QQ 交流群  
![qq_group](./docs/images/fijkplayer_qq_group.jpg)


## 开发计划

下一步 v0.2.0 版本计划可以在 https://github.com/befovy/fijkplayer/projects/2 中查看
