package com.befovy.fijkplayer;

import android.util.Log;

import io.flutter.view.TextureRegistry;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FijkplayerPlugin */
public class FijkPlugin implements MethodCallHandler {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "befovy.com/fijk");

    // registrar.textures().createSurfaceTexture()

    channel.setMethodCallHandler(new FijkPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("init")){
      Log.i("FLUTTER", "call init:" + call.arguments.toString());
    } else {
      result.notImplemented();
    }
  }
}
