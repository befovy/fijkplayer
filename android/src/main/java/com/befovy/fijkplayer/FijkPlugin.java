package com.befovy.fijkplayer;

import android.content.Context;
import android.net.Uri;
import android.util.Log;
import android.util.LongSparseArray;
import android.util.SparseArray;

import java.io.IOException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;

/**
 * FijkPlugin
 */
public class FijkPlugin implements MethodCallHandler {
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "befovy.com/fijk");
        channel.setMethodCallHandler(new FijkPlugin(registrar, registrar.context()));
    }

    final private Registrar registrar;
    final private SparseArray<FijkPlayer> fijkPlayers;
    final private Context context;

    private FijkPlugin(Registrar registrar, Context context) {
        this.registrar = registrar;
        this.context = context;
        fijkPlayers = new SparseArray<>();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.i("FLUTTER", "onMethod Call, name: " + call.method);
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("init")) {
            Log.i("FLUTTER", "call init:" + call.arguments.toString());
            result.success(null);
        } else if (call.method.equals("createPlayer")) {
            FijkPlayer fijkPlayer = new FijkPlayer(registrar);
            int playerId = fijkPlayer.getPlayerId();
            fijkPlayers.append(playerId, fijkPlayer);
            result.success(playerId);
        } else if (call.method.equals("releasePlayer")) {
            int pid = call.argument("pid");
            FijkPlayer fijkPlayer = fijkPlayers.get(pid);
            if (fijkPlayer != null) {
                fijkPlayer.release();
                fijkPlayers.delete(pid);
            }
            result.success(null);
        } else {
            result.notImplemented();
        }
    }
}