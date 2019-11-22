package com.befovy.fijkplayer;

import java.util.HashMap;
import java.util.Map;

final class HostOption {

    final public static String REQUEST_AUDIOFOCUS = "request-audio-focus";
    final public static String RELEASE_AUDIOFOCUS = "release-audio-focus";

    final private Map<String, Integer> mIntOption;

    final private Map<String, String> mStrOption;


    public HostOption() {
        this.mIntOption = new HashMap<>();
        this.mStrOption = new HashMap<>();
    }


    public void addIntOption(String key, Integer value) {
        mIntOption.put(key, value);
    }

    public void addStrOption(String key, String value) {
        mStrOption.put(key, value);
    }

    public int getIntOption(String key, int defalt) {
        int value = defalt;
        if (mIntOption.containsKey(key)) {
            Integer v = mIntOption.get(key);
            if (v != null)
                value = v;
        }
        return value;
    }

    public String getStrOption(String key, String defalt) {
        String value = defalt;
        if (mStrOption.containsKey(key)) {
            String v = mStrOption.get(key);
            if (v != null)
                value = v;
        }
        return value;
    }
}
