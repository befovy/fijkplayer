# fijkplayer (Video player plugin for Flutter) Flutter 媒体播放器

✨ **[手把手带你写 Flutter 系统音量插件](https://www.yuque.com/befovy/share/flutter_volume)**  ✨  **[Flutter 多版本管理工具 fvm](https://github.com/befovy/fvm)** ✨

[![HitCount](https://hits.dwyl.com/befovy/fijkplayer.svg)](https://hits.dwyl.com/befovy/fijkplayer) &nbsp; &nbsp;
[![pub package](https://img.shields.io/pub/v/fijkplayer.svg)](https://pub.dartlang.org/packages/fijkplayer) &nbsp; &nbsp;
[![Action Status](https://github.com/befovy/fijkplayer/workflows/Flutter/badge.svg?branch=master)](https://github.com/befovy/fijkplayer/actions) &nbsp; &nbsp;


A Flutter media player plugin for iOS and android based on [ijkplayer](https://github.com/befovy/ijkplayer)

您的支持是我们开发的动力。 欢迎Star，欢迎PR~。
[Feedback welcome](https://github.com/befovy/fijkplayer/issues) and
[Pull Requests](https://github.com/befovy/fijkplayer/pulls) are most welcome!

## Documentation 文档

* Development Documentation https://fijkplayer.befovy.com/docs/en/ quick start、guide、and concepts about fijkplayer 
* 开发文档  https://fijkplayer.befovy.com/docs/zh/ 包含快速开始、使用指南、fijkplayer 中的概念理解
* dart api https://pub.dev/documentation/fijkplayer/ detail API and argument explaination
* Release Notes https://github.com/befovy/fijkplayer/releases and [CHANGELOG.md](./CHANGELOG.md)
* FAQ https://fijkplayer.befovy.com/docs/zh/faq.html

## Installation 安装

Add `fijkplayer` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/). 

[![pub package](https://img.shields.io/pub/v/fijkplayer.svg)](https://pub.dartlang.org/packages/fijkplayer)

```yaml
dependencies:
  fijkplayer: ^{{latest version}}
```

Replace `{{latest version}}` with the version number in badge above.

Use git branch which not published to pub.
```yaml
dependencies:
  fijkplayer:
    git:
      url: https://github.com/befovy/fijkplayer.git
      ref: develop # can be replaced to branch or tag name
```

## Example 示例

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

## Contributors 贡献者 ✨

Thanks goes to [these wonderful people](./CONTRIBUTORS.md) ([emoji key](https://allcontributors.org/docs/en/emoji-key))

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome

## iOS Warning 警告

Warning: The fijkplayer video player plugin is not functional on iOS simulators. An iOS device must be used during development/testing. For more details, please refer to this [issue](https://github.com/flutter/flutter/issues/14647).


## Join Ding Talk Group 加入钉钉群

<div>
  <table>
    <thead><tr>
      <th>加入钉钉群</th>
      <th>微信赞赏码</th>
      <th>支付宝</th>
    </tr></thead>
    <tbody><tr>
      <td>
        <img width="200" height="200" src="https://cdn.jsdelivr.net/gh/befovy/fijkplayer@master/docs/images/dingtalk.jpg" alt="加入钉钉群" />
      </td>
      <td>
        <img width="200" height="200" src="https://cdn.jsdelivr.net/gh/befovy/images@master/assets/wechat-qr-code.jpeg" alt="微信赞赏码" />
      </td>
      <td>
        <img width="200" height="200" src="https://cdn.jsdelivr.net/gh/befovy/images@master/assets/alipay-qr-code.jpeg" alt="支付宝二维码" />
      </td>
    </tr></tbody>
  </table>
</div>
