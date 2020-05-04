import 'package:flutter/material.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'app_bar.dart';
import 'media_item.dart';

const List<MediaUrl> samples = [
  MediaUrl(
      title: "Aliyun", url: "http://player.alicdn.com/video/aliyunmedia.mp4"),
  MediaUrl(
      title: "http 404", url: "https://fijkplayer.befovy.com/butterfly.flv"),
  MediaUrl(title: "assets file", url: "asset:///assets/butterfly.mp4"),
  MediaUrl(title: "assets file", url: "asset:///assets/birthday.mp4"),
  MediaUrl(title: "assets file 404", url: "asset:///assets/beebee.mp4"),
  MediaUrl(
      title: "Protocol not found", url: "noprotocol://assets/butterfly.mp4"),
  MediaUrl(
      title: "rtsp test",
      url: "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov"),
  MediaUrl(
      title: "Sample Video 360 * 240",
      url:
          "https://sample-videos.com/video123/flv/240/big_buck_bunny_240p_10mb.flv"),
  MediaUrl(
      title: "bipbop basic master playlist",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"),
  MediaUrl(
      title: "bipbop basic 400x300 @ 232 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop basic 640x480 @ 650 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop basic 640x480 @ 1 Mbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear3/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop basic 960x720 @ 2 Mbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear4/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop basic 22.050Hz stereo @ 40 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced master playlist",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"),
  MediaUrl(
      title: "bipbop advanced 416x234 @ 265 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear1/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced 640x360 @ 580 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear2/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced 960x540 @ 910 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear3/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced 1280x720 @ 1 Mbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear4/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced 1920x1080 @ 2 Mbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear5/prog_index.m3u8"),
  MediaUrl(
      title: "bipbop advanced 22.050Hz stereo @ 40 kbps",
      url:
          "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear0/prog_index.m3u8"),
];

class SamplesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Online Samples"),
      body: ListView.builder(
          itemCount: samples.length,
          itemBuilder: (BuildContext context, int index) {
            MediaUrl mediaUrl = samples[index];
            return MediaItem(mediaUrl: mediaUrl);
          }),
    );
  }
}

class RecentMediaList extends StatefulWidget {
  @override
  _RecentMediaListState createState() => _RecentMediaListState();
}

class _RecentMediaListState extends State<RecentMediaList> {
  int recentCount = 0;
  int newestId = 0;
  StreamingSharedPreferences prefs;
  ScrollController _controller = ScrollController();

  _RecentMediaListState() {
    asyncSetup();
  }

  asyncSetup() async {
    prefs = await StreamingSharedPreferences.instance;

    Preference<int> counter = prefs.getInt('recent_count', defaultValue: 0);
    counter.listen(onHistoryChanged);
  }

  onHistoryChanged(int v) {
    int count = prefs.getInt("recent_count", defaultValue: 0).getValue();
    int newest = prefs.getInt("recent_newest", defaultValue: 0).getValue();
    _controller.jumpTo(0);
    setState(() {
      recentCount = count;
      newestId = newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        controller: _controller,
        itemCount: recentCount > 20 ? 20 : recentCount,
        itemBuilder: (BuildContext context, int index) {
          index = ((newestId + 20) - index) % 20;
          final key = "recentid" + index.toString();
          MediaUrl item = prefs
              .getCustomValue<MediaUrl>(key,
                  defaultValue: MediaUrl(url: ""),
                  adapter: JsonAdapter(
                    deserializer: (value) => MediaUrl.fromJson(value),
                  ))
              .getValue();
          return MediaItem(mediaUrl: item);
        });
  }
}

Future<void> addToHistory(MediaUrl mediaUrl) async {
  StreamingSharedPreferences prefs = await StreamingSharedPreferences.instance;
  int newest = prefs.getInt("recent_newest", defaultValue: 0).getValue();
  int count = prefs.getInt("recent_count", defaultValue: 0).getValue();

  if (count > 0) {
    MediaUrl theNewest = prefs
        .getCustomValue<MediaUrl>("recentid" + newest.toString(),
            defaultValue: MediaUrl(url: ""),
            adapter: JsonAdapter(
              deserializer: (value) => MediaUrl.fromJson(value),
            ))
        .getValue();

    if (theNewest.url != mediaUrl.url) {
      newest = (newest + 1) % 20;
      count += 1;
    } else {
      newest = -1;
    }
  } else {
    count += 1;
  }

  if (newest >= 0) {
    await prefs.setInt("recent_count", count);
    await prefs.setInt("recent_newest", newest);
    await prefs.setCustomValue<MediaUrl>(
        "recentid" + newest.toString(), mediaUrl,
        adapter: JsonAdapter(
          deserializer: (value) => MediaUrl.fromJson(value),
        ));
  }
}
