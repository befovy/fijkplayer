/**
 * 参考：ijkplayer/src/main/cpp/ijkplayer/ijkplayer_android_def.h
 */
export class MediaInfoType {
  static readonly MEDIA_INFO_UNKNOWN = 1;
  static readonly MEDIA_INFO_STARTED_AS_NEXT = 2;
  static readonly MEDIA_INFO_VIDEO_RENDERING_START = 3;
  static readonly MEDIA_INFO_VIDEO_TRACK_LAGGING = 700;
  static readonly MEDIA_INFO_BUFFERING_START = 701;
  static readonly MEDIA_INFO_BUFFERING_END = 702;
  static readonly MEDIA_INFO_NETWORK_BANDWIDTH = 703;
  static readonly MEDIA_INFO_BAD_INTERLEAVING = 800;
  static readonly MEDIA_INFO_NOT_SEEKABLE = 801;
  static readonly MEDIA_INFO_METADATA_UPDATE = 802;
  static readonly MEDIA_INFO_TIMED_TEXT_ERROR = 900;
  static readonly MEDIA_INFO_VIDEO_ROTATION_CHANGED = 10001;
  static readonly MEDIA_INFO_AUDIO_RENDERING_START = 10002;
  static readonly MEDIA_INFO_AUDIO_DECODED_START = 10003;
  static readonly MEDIA_INFO_VIDEO_DECODED_START = 10004;
  static readonly MEDIA_INFO_OPEN_INPUT = 10005;
  static readonly MEDIA_INFO_FIND_STREAM_INFO = 10006;
  static readonly MEDIA_INFO_COMPONENT_OPEN = 10007;
  static readonly MEDIA_INFO_VIDEO_SEEK_RENDERING_START = 10008;
  static readonly MEDIA_INFO_AUDIO_SEEK_RENDERING_START = 10009;
  static readonly MEDIA_INFO_MEDIA_ACCURATE_SEEK_COMPLETE = 10100;
}


/**
 * 播放器的状态
 */
export enum PlayerState {
  unkown = -1,
  idle = 0,
  initialized = 1,
  asyncPreparing = 2,
  prepared = 3,
  started = 4,
  paused = 5,
  completed = 6,
  stopped = 7,
  error = 8,
  end = 9,
}


export class OptionsCategory {
  static readonly OPT_CATEGORY_FORMAT = 1;
  static readonly OPT_CATEGORY_CODEC = 2;
  static readonly OPT_CATEGORY_SWS = 3;
  static readonly OPT_CATEGORY_PLAYER = 4;
}