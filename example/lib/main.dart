import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // FijkLog.setLevel(FijkLogLevel.Debug);
    return new MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFFffd54f),
        primaryColorDark: Color(0xFFffc107),
        primaryColorLight: Color(0xFFffecb3),
        accentColor: Color(0xFFFFC107),
        dividerColor: Color(0xFFBDBDBD),
      ),
      home: HomeScreen(),
    );
  }
}
