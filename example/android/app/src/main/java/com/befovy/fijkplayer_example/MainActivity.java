package com.befovy.fijkplayer_example;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;

import com.befovy.fijkplayer.PluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    PluginRegistrant.registerWith(this);
  }
}
