# fijkplayer (Video player plugin for Flutter)


[![pub package](https://img.shields.io/pub/v/fijkplayer.svg)](https://pub.dartlang.org/packages/fijkplayer) &nbsp; &nbsp;
[![Build Status](https://travis-ci.org/befovy/fijkplayer.svg?branch=master)](https://travis-ci.org/befovy/fijkplayer) &nbsp; &nbsp;

A Flutter media player plugin for iOS and android based on [ijkplayer](https://github.com/befovy/ijkplayer)


*Read this in other languages: [English](README.en.md), [简体中文](README.zh-cn.md).*


[Feedback welcome](https://github.com/befovy/fijkplayer/issues) and
[Pull Requests](https://github.com/befovy/fijkplayer/pulls) are most welcome!

## Installation

Add `fijkplayer` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/). 

```yaml
dependencies:
  fijkplayer: ^0.1.1
```


## Example

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

## Demo Screenshots

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



## iOS Warning

Warning: The fijkplayer video player plugin is not functional on iOS simulators. An iOS device must be used during development/testing. For more details, please refer to this [issue](https://github.com/flutter/flutter/issues/14647).

