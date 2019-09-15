package com.befovy.fijkplayer;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;
import android.util.SparseArray;
import android.view.KeyEvent;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;

/**
 * FijkPlugin
 */
public class FijkPlugin implements MethodCallHandler, FijkVolume.VolumeKeyListener {

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "befovy.com/fijk");
        _instance = new FijkPlugin(registrar);
        channel.setMethodCallHandler(_instance);

        final FijkPlayer player = new FijkPlayer(registrar);
        player.setupSurface();
        player.release();
    }

    public static FijkPlugin instance() {
        return _instance;
    }

    private static FijkPlugin _instance;

    //    final private Activity activity;
    final private Registrar registrar;
    final private SparseArray<FijkPlayer> fijkPlayers;

    // Count of playable players
    private int playableCnt = 0;

    // Count of playing players
    private int playingCnt = 0;

    // show system volume changed UI if no playable player
    // hide system volume changed UI if some players are in playable state
    private static int NO_UI_IF_PLAYABLE = 0;

    // show system volume changed UI if no start state player
    // hide system volume changed UI if some players are in start state
    private static int NO_UI_IF_PLAYING = 1;

    // never show system volume changed UI
    private static int NEVER_SHOW_UI = 2;
    // always show system volume changed UI
    private static int ALWAYS_SHOW_UI = 3;

    private int volumeUIMode = ALWAYS_SHOW_UI;
    private float volStep = 1.0f / 16.0f;

    private boolean eventListening = false;

    // non-local field prevent GC
    @SuppressWarnings("FieldCanBeLocal")
    final private EventChannel mEventChannel;

    final QueuingEventSink mEventSink = new QueuingEventSink();


    private FijkPlugin(Registrar registrar) {
        this.registrar = registrar;
        fijkPlayers = new SparseArray<>();
        Activity activity = registrar.activity();

        if (activity instanceof FijkVolume.CanListenVolumeKey) {
            FijkVolume.CanListenVolumeKey canListenVolumeKey = (FijkVolume.CanListenVolumeKey) activity;
            canListenVolumeKey.setVolumeKeyListener(this);
        }

        mEventChannel = new EventChannel(registrar.messenger(), "befovy.com/fijk/event");
        mEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink.setDelegate(eventSink);
            }

            @Override
            public void onCancel(Object o) {
                mEventSink.setDelegate(null);
            }
        });

        int max = audioManager().getStreamMaxVolume(AudioManager.STREAM_MUSIC);

        volStep = Math.max(1.0f / (float) max, volStep);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Activity activity = registrar.activity();
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
                int pid = -1;
                if (call.hasArgument("pid"))
                    pid = call.argument("pid");
                FijkPlayer fijkPlayer = fijkPlayers.get(pid);
                if (fijkPlayer != null) {
                    fijkPlayer.release();
                    fijkPlayers.delete(pid);
                }
                result.success(null);
                break;
            }
            case "logLevel": {
                int level = 500;
                if (call.hasArgument("level"))
                    level = call.argument("level");
                level = level / 100;
                level = level < 0 ? 0 : level;
                level = level > 8 ? 8 : level;
                IjkMediaPlayer.native_setLogLevel(level);
                result.success(null);
                break;
            }
            case "setOrientationPortrait":
                if (activity != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT);
                    } else {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
                    }
                }
                result.success(null);
                break;
            case "setOrientationLandscape":
                if (activity != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE);
                    } else {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
                    }
                }
                result.success(null);
                break;
            case "setOrientationAuto":
                if (activity != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_FULL_USER);
                    } else {
                        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR);
                    }
                }
                result.success(null);
                break;
            case "volumeDown":
                result.success(volumeDown());
                break;
            case "volumeUp":
                result.success(volumeUp());
                break;
            case "volumeMute":
                result.success(volumeMute());
                break;
            case "systemVolume":
                result.success(systemVolume());
                break;
            case "volumeSet":
                float vol = systemVolume();
                if (call.hasArgument("vol")) {
                    float v = call.argument("vol");
                    vol = setSystemVolume(v);
                }
                result.success(vol);
            case "volUiMode":
                if (call.hasArgument("mode"))
                    volumeUIMode = call.argument("mode");
                result.success(null);
                break;
            case "onLoad":
                eventListening = true;
                result.success(null);
                break;
            case "onUnload":
                eventListening = false;
                result.success(null);
                break;
            default:
                Log.w("FLUTTER", "onMethod Call, name: " + call.method);
                result.notImplemented();
                break;
        }
    }

    void onPlayingChange(int delta) {
        playingCnt += delta;
    }

    void onPlayableChange(int delta) {
        playableCnt += delta;
    }

    public int getPlayableCnt() {
        return playableCnt;
    }

    public int getPlayingCnt() {
        return playingCnt;
    }

    private AudioManager audioManager() {
        Activity activity = registrar.activity();
        return (AudioManager) activity.getSystemService(Context.AUDIO_SERVICE);
    }

    public float systemVolume() {
        AudioManager audioManager = audioManager();
        float max = (float) audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        float vol = (float) audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        return vol / max;
    }

    private void sendVolumeEvent() {
        if (eventListening) {
            int flag = getVolumeChangeFlag();
            boolean showOsUI = (flag & AudioManager.FLAG_SHOW_UI) > 0;
            Map<String, Object> event = new HashMap<>();
            event.put("event", "volume");
            event.put("sui", showOsUI);
            event.put("vol", systemVolume());
            mEventSink.success(event);
        }
    }

    public float volumeUp() {
        float vol = systemVolume();
        vol = vol + volStep;
        vol = setSystemVolume(vol);
        return vol;
    }

    public float volumeDown() {
        float vol = systemVolume();
        vol = vol - volStep;
        vol = setSystemVolume(vol);
        return vol;
    }

    public float volumeMute() {
        setSystemVolume(0.0f);
        return 0.0f;
    }

    private int getVolumeChangeFlag() {
        int flag = 0;
        if (volumeUIMode == ALWAYS_SHOW_UI) {
            flag = AudioManager.FLAG_SHOW_UI;
        } else if (volumeUIMode == NO_UI_IF_PLAYING && playingCnt == 0) {
            flag = AudioManager.FLAG_SHOW_UI;
        } else if (volumeUIMode == NO_UI_IF_PLAYABLE && playableCnt == 0) {
            flag = AudioManager.FLAG_SHOW_UI;
        }
        return flag;
    }

    private float setSystemVolume(float vol) {
        int flag = getVolumeChangeFlag();
        AudioManager audioManager = audioManager();
        int max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        int volIndex = (int) (vol * max);
        volIndex = Math.min(volIndex, max);
        volIndex = Math.max(volIndex, 0);
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volIndex, flag);
        sendVolumeEvent();
        return (float) volIndex / (float) max;
    }

    @Override
    public boolean onVolumeKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_VOLUME_DOWN:
                volumeDown();
                return true;
            case KeyEvent.KEYCODE_VOLUME_UP:
                volumeUp();
                return true;
            case KeyEvent.KEYCODE_VOLUME_MUTE:
                volumeMute();
                return true;
        }
        return false;
    }
}