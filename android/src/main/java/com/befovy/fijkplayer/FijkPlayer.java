package com.befovy.fijkplayer;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.TextureRegistry;
import tv.danmaku.ijk.media.player.IjkEventListener;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;

public class FijkPlayer implements MethodChannel.MethodCallHandler, IjkEventListener {

    final private static AtomicInteger atomicId = new AtomicInteger(0);

    final private int mPlayerId;
    final private IjkMediaPlayer mIjkMediaPlayer;
    final private Context mContext;

    @SuppressWarnings("FieldCanBeLocal")
    final private EventChannel mEventChannel;
    @SuppressWarnings("FieldCanBeLocal")
    final private MethodChannel mMethodChannel;

    final private PluginRegistry.Registrar mRegistrar;

    final private QueuingEventSink mEventSink = new QueuingEventSink();

    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    FijkPlayer(PluginRegistry.Registrar registrar) {
        mRegistrar = registrar;
        mPlayerId = atomicId.incrementAndGet();
        mIjkMediaPlayer = new IjkMediaPlayer();
        mIjkMediaPlayer.addIjkEventListener(this);

        mContext = registrar.context();
        IjkMediaPlayer.native_setLogLevel(IjkMediaPlayer.IJK_LOG_INFO);
        mMethodChannel = new MethodChannel(registrar.messenger(), "befovy.com/fijkplayer/" + mPlayerId);
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(registrar.messenger(), "befovy.com/fijkplayer/event/" + mPlayerId);
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

    }

    int getPlayerId() {
        return mPlayerId;
    }

    long setupSurface() {
        if (mSurfaceTextureEntry == null) {
            TextureRegistry textureRegistry = mRegistrar.textures();
            TextureRegistry.SurfaceTextureEntry surfaceTextureEntry = textureRegistry.createSurfaceTexture();
            mSurfaceTextureEntry = surfaceTextureEntry;
            mSurfaceTexture = surfaceTextureEntry.surfaceTexture();
            mSurface = new Surface(mSurfaceTexture);
            mIjkMediaPlayer.setSurface(mSurface);
        }
        return mSurfaceTextureEntry.id();
    }

    void release() {
        mIjkMediaPlayer.stop();
        mIjkMediaPlayer.release();

        if (mSurfaceTextureEntry != null) {
            mSurfaceTextureEntry.release();
            mSurfaceTextureEntry = null;
        }
        if (mSurfaceTexture != null) {
            mSurfaceTexture.release();
            mSurfaceTexture = null;
        }
        if (mSurface != null) {
            mSurface.release();
            mSurface = null;
        }
    }

    private void handleEvent(int what, int arg1, int arg2, Object extra) {
        Map<String, Object> event = new HashMap<>();

        switch (what) {
            case PREPARED:
                event.put("event", "prepared");
                long duration = mIjkMediaPlayer.getDuration();
                event.put("duration", duration);
                mEventSink.success(event);
                break;
            case PLAYBACK_STATE_CHANGED:
                event.put("event", "state_change");
                event.put("new", arg1);
                event.put("old", arg2);
                mEventSink.success(event);
                break;

            case BUFFERING_START:
            case BUFFERING_END:
                event.put("event", "freeze");
                event.put("value", what == BUFFERING_START);
                mEventSink.success(event);
                break;

            // play position
            // case the duration of the file

            // buffer / cache position
            case BUFFERING_UPDATE:
                event.put("event", "buffering");
                event.put("head", arg1);
                event.put("percent", arg2);
                mEventSink.success(event);
                break;

            case VIDEO_SIZE_CHANGED:
                event.put("event", "size_changed");
                event.put("width", arg1);
                event.put("height", arg2);
                mEventSink.success(event);
                break;
            default:
                // Log.d("FLUTTER", "jonEvent:" + what);
                break;
        }
    }

    @Override
    public void onEvent(IjkMediaPlayer ijkMediaPlayer, int what, int arg1, int arg2, Object extra) {
        switch (what) {
            case PREPARED:
            case PLAYBACK_STATE_CHANGED:
            case BUFFERING_START:
            case BUFFERING_END:
            case BUFFERING_UPDATE:
            case VIDEO_SIZE_CHANGED:
                handleEvent(what, arg1, arg2, extra);
                break;
            default:
                break;
        }
    }


    private void applyOptions(Object options) {
        if (options instanceof Map) {
            Map optionsMap = (Map) options;
            for (Object o : optionsMap.keySet()) {
                Object option = optionsMap.get(o);
                if (o instanceof Integer && option instanceof Map) {
                    Integer cat = (Integer) o;
                    Map optionMap = (Map) option;
                    for (Object key : optionMap.keySet()) {
                        Object value = optionMap.get(key);
                        if (key instanceof String) {
                            String name = (String) key;
                            if (value instanceof Integer) {
                                mIjkMediaPlayer.setOption(cat, name, (Integer) value);
                            } else if (value instanceof String) {
                                mIjkMediaPlayer.setOption(cat, name, (String) value);
                            }
                        }
                    }
                }
            }
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("setupSurface")) {
            long viewId = setupSurface();
            result.success(viewId);
        } else if (call.method.equals("setOption")) {
            Integer category = call.argument("cat");
            final String key = call.argument("key");
            if (call.hasArgument("long")) {
                final Integer value = call.argument("long");
                mIjkMediaPlayer.setOption(category != null ? category : 0, key, value != null ? value.longValue() : 0);
            } else if (call.hasArgument("str")) {
                final String value = call.argument("str");
                mIjkMediaPlayer.setOption(category != null ? category : 0, key, value);
            } else {
                Log.w("FIJKPLAYER", "error arguments for setOptions");
            }
            result.success(null);
        } else if (call.method.equals("applyOptions")) {
            applyOptions(call.arguments);
            result.success(null);
        } else if (call.method.equals("setDateSource")) {
            String url = call.argument("url");
            try {
                mIjkMediaPlayer.setDataSource(mContext, Uri.parse(url));
                result.success(null);
            } catch (IOException e) {
                result.error(e.getMessage(), null, null);
            }
        } else if (call.method.equals("prepareAsync")) {
            mIjkMediaPlayer.prepareAsync();
            result.success(null);
        } else if (call.method.equals("start")) {
            mIjkMediaPlayer.start();
            result.success(null);
        } else if (call.method.equals("pause")) {
            mIjkMediaPlayer.pause();
            result.success(null);
        } else if (call.method.equals("stop")) {
            mIjkMediaPlayer.stop();
            result.success(null);
        } else if (call.method.equals("reset")) {
            mIjkMediaPlayer.reset();
            result.success(null);
        } else if (call.method.equals("getCurrentPosition")) {
            long pos = mIjkMediaPlayer.getCurrentPosition();
            result.success(pos);
        } else if (call.method.equals("setVolume")) {
            final Double volume = call.argument("volume");
            float vol = volume != null ? volume.floatValue() : 1.0f;
            mIjkMediaPlayer.setVolume(vol, vol);
            result.success(null);
        } else if (call.method.equals("seekTo")) {
            final Integer msec = call.argument("msec");
            mIjkMediaPlayer.seekTo(msec != null ? msec.longValue() : 0);
            result.success(null);
        } else if (call.method.equals("setLoop")) {
            final Integer loopCount = call.argument("loop");
            // todo update ijkplayer, add set loop count api
            mIjkMediaPlayer.setLooping(loopCount != null && loopCount == 0);
            result.success(null);
        } else if (call.method.equals("setSpeed")) {
            final Double speed = call.argument("speed");
            mIjkMediaPlayer.setSpeed(speed != null ? speed.floatValue() : 1.0f);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }
}
