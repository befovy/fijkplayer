package com.befovy.fijkplayer;

import android.util.Log;
import android.util.SparseArray;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FijkPlugin
 */
public class FijkPlugin implements MethodCallHandler {
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "befovy.com/fijk");
        channel.setMethodCallHandler(new FijkPlugin(registrar));
    }

    final private Registrar registrar;
    final private SparseArray<FijkPlayer> fijkPlayers;

    private FijkPlugin(Registrar registrar ) {
        this.registrar = registrar;
        fijkPlayers = new SparseArray<>();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "init":
                Log.i("FLUTTER", "call init:" + call.arguments.toString());
                result.success(null);
                break;
            case "createPlayer": {
                FijkPlayer fijkPlayer = new FijkPlayer(registrar);
                int playerId = fijkPlayer.getPlayerId();
                fijkPlayers.append(playerId, fijkPlayer);
                result.success(playerId);
                break;
            }
            case "releasePlayer": {
                int pid = call.argument("pid");
                FijkPlayer fijkPlayer = fijkPlayers.get(pid);
                if (fijkPlayer != null) {
                    fijkPlayer.release();
                    fijkPlayers.delete(pid);
                }
                result.success(null);
                break;
            }
            default:
                Log.w("FLUTTER", "onMethod Call, name: " + call.method);
                result.notImplemented();
                break;
        }
    }
}