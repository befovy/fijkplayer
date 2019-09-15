package com.befovy.fijkplayer;

import android.view.KeyEvent;

public class FijkVolume {


    public interface VolumeKeyListener {
        boolean onVolumeKeyDown(int keyCode, KeyEvent event);
    }

    public interface CanListenVolumeKey {
        void setVolumeKeyListener(VolumeKeyListener listener);
    }
}
