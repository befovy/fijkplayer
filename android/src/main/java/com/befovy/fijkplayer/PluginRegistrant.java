package com.befovy.fijkplayer;


import io.flutter.plugin.common.PluginRegistry;

public final class PluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    FijkPlugin.registerWith(registry.registrarFor("com.befovy.fijkplayer.FijkPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = PluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
