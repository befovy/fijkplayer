import 'dart:async';

import 'package:fijkplayer/fijkplugin.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer/fijkview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';


  FijkPlayer _player;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FijkPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }


    FijkPlayer player = FijkPlayer();
    player.setDataSource(DateSourceType.network, "http://ivi.bupt.edu.cn/hls/cctv1.m3u8");
    player.start();
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _player = player;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(

          child: Column(
            children: <Widget>[
              Text('Running on: $_platformVersion\n'),
              _player == null ? Container(
                color: Color.fromRGBO(200, 200, 200, 0.5),
              ) : FijkView(_player),
            ],
          )
        ),
      ),
    );
  }
}
