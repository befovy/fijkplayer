package com.befovy.fijkplayer.demo;

import android.os.Bundle;
import android.view.KeyEvent;

import com.befovy.fijkplayer.FijkVolume;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity implements FijkVolume.CanListenVolumeKey {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
    }

    private FijkVolume.VolumeKeyListener volumeKeyListener;

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_VOLUME_DOWN:
            case KeyEvent.KEYCODE_VOLUME_UP:
            case KeyEvent.KEYCODE_VOLUME_MUTE:
                if (volumeKeyListener != null)
                    return volumeKeyListener.onVolumeKeyDown(keyCode, event);
        }
        return super.onKeyDown(keyCode, event);
    }


    @Override
    public void setVolumeKeyListener(FijkVolume.VolumeKeyListener listener) {
        volumeKeyListener = listener;
    }
}
