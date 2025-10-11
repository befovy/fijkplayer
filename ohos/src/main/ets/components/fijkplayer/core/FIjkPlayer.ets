import {
  EventChannel,
  EventSink,
  FlutterInjector,
  FlutterManager,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler
} from '@ohos/flutter_ohos';
import { IjkMediaPlayer, MessageType, OnMessageCallback } from '@zaiohos/ijkplayer-surface';
import { HashMap, uri } from '@kit.ArkTS';
import { MediaInfoType, OptionsCategory, PlayerState } from '../common/Constants';
import HostOption from '../common/HostOption';
import { getFilePathByAssetsPath } from '../common/AssetsCopyUtil';

const TAG = "FIjkPlayerTag";
const DEFAULT_WIDTH = 500;
const DEFAULT_HEIGHT = 500;

export class FIjkPlayer implements MethodCallHandler, StreamHandler, OnMessageCallback {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private binding: FlutterPluginBinding;
  private id: number;
  private textureId?: number;
  private surfaceId?: number;
  private player?: IjkMediaPlayer;
  private currentPlayerState: number = PlayerState.unkown;
  private mWidth: number = 0;
  private mHeight: number = 0;
  private mRotate: number = 0;
  private hasReset: boolean = false;
  private mHostOption: HostOption = new HostOption();

  constructor(id: number, binding: FlutterPluginBinding) {
    this.id = id;
    this.binding = binding;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "befovy.com/fijkplayer/" + this.id);
    this.channel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), "befovy.com/fijkplayer/event/" + this.id);
    this.eventChannel.setStreamHandler(this);
    this.initPlayer();
  }

  onListen(args: ESObject, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: ESObject): void {
    this.eventSink?.endOfStream();
  }

  initPlayer() {
    this.player = new IjkMediaPlayer();
    //surface模式下，其它方法都依赖surfaceId，需要先设置surfaceId
    this.setSurfaceId();
    this.player.setDebug(true);
    this.setUpPlayer();
    this.player.setOnMessageCallback(this);
    this.player.setMessageListener();
  }

  setUpPlayer() {
    if (!this.player) {
      return;
    }
    this.player.native_setup();
    this.player.setOption(OptionsCategory.OPT_CATEGORY_PLAYER.toString(), "enable-position-notify", '1');
    this.player.setOption(OptionsCategory.OPT_CATEGORY_PLAYER.toString(), "start-on-prepared", '0');
  }

  /**
   * 纹理导出模式下，需更新bufferSize配置
   * @param width
   * @param height
   */
  updateSurfaceWH(width: number, height: number) {
    this.binding.getTextureRegistry().setTextureBufferSize(this.textureId, width, height);
  }

  setSurfaceId() {
    this.textureId = this.binding.getTextureRegistry().getTextureId();
    this.surfaceId = this.binding.getTextureRegistry().registerTexture(this.textureId).getSurfaceId();
    this.player?.setSurfaceId(this.surfaceId);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    Log.d(TAG, 'onMethodCall=' + methodName);
    switch (methodName) {
      case "setupSurface":
        result.success(this.textureId);
        break;
      case "setOption":
        const category: number = call.argument('cat');
        const key: string = call.argument("key");
        if (call.hasArgument('long')) {
          const value: number = call.argument('long');
          this.setOption(category, key, value);
        } else if (call.hasArgument('str')) {
          const value: string = call.argument('str');
          this.setOption(category, key, value);
        }
        result.success(null);
        break;
      case "applyOptions":
        if (call.args instanceof Map) {
          const map: Map<ESObject, ESObject> = call.args as Map<ESObject, ESObject>;
          map.forEach((key: ESObject, value: ESObject) => {
            if (typeof key === 'number' && value instanceof Map) {
              const category = key as number;
              const valueMap: Map<ESObject, ESObject> = value as Map<ESObject, ESObject>;
              valueMap.forEach((key: ESObject, value: ESObject) => {
                if (typeof key === 'string') {
                  const keyStr = key as string;
                  this.setOption(category, keyStr, value);
                }
              })
            }
          })
        }
        result.success(null);
        break;
      case "setDataSource":
        if(this.hasReset){
            this.setUpPlayer();
            this.hasReset = false;
        }
        const url: string = call.argument('url');
        const uriObj = new uri.URI(url);
        if (uriObj.scheme === 'asset') {
          const filePath = uriObj.path;
          this.player?.setDataSource(getFilePathByAssetsPath(this.binding.getApplicationContext(),filePath));
        } else {
          this.player?.setDataSource(url);
        }
        this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.initialized, PlayerState.unkown, null);
        result.success(null);
        break;
      case "prepareAsync":
        if (this.player) {
          this.player.prepareAsync();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.asyncPreparing,
            this.currentPlayerState,
            null);
        }
        result.success(null);
        break;
      case "start":
        if (this.player) {
          this.player.start();
        }
        result.success(null);
        break;
      case "pause":
        if (this.player) {
          this.player.pause();
        }
        result.success(null);
        break;
      case "stop":
        if (this.player) {
          this.player.stop();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.stopped, this.currentPlayerState,
            null);
        }
        result.success(null);
        break;
      case "reset":
        if (this.player) {
          this.player.reset();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.idle, this.currentPlayerState, null);
          this.hasReset = true;
        }
        result.success(null);
        break;
      case "getCurrentPosition":
        const position: number | undefined = this.player?.getCurrentPosition();
        result.success(position ? position : 0);
        break;
      case "setVolume":
        const volume: number = call.argument('volume');
        const volumeStr = volume == undefined ? '1.0' : volume.toString();
        this.player?.setVolume(volumeStr, volumeStr);
        result.success(null);
        break;
      case "seekTo":
        const msec: number = call.argument('msec');
        if (this.currentPlayerState == PlayerState.completed) {
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.paused, this.currentPlayerState, null);
        }
        const msecStr = msec == undefined ? '0' : msec.toString();
        this.player?.seekTo(msecStr);
        result.success(null);
        break;
      case "setLoop":
        const loop: number = call.argument('loop');
        const loopLocal = loop == undefined ? 1 : loop;
        this.player?.setLoopCountNum(loopLocal);
        result.success(null);
        break;
      case "setSpeed":
        const speed: number = call.argument('speed');
        const speedLocal = speed == undefined ? 1 : speed;
        this.player?.setSpeed(speedLocal.toString());
        result.success(null);
        break;
      case "snapshot":
        result.notImplemented;
        break;

    }
  }

  onPlayerStateChangeLocal(newState: number, oldState: number) {

  }

  onMessage(what: number, arg1: number, arg2: number, obj: string) {
    this.handleEvent(what, arg1, arg2, obj);
  }

  handleEvent(what: number, arg1: number, arg2: number, extra: ESObject) {
    Log.d(TAG, 'handleEvent(),what' + what);
    const event: HashMap<string, ESObject> = new HashMap();
    switch (what) {
      case MessageType.MEDIA_PREPARED:
        event.set('event', 'prepared');
        event.set('duration', this.player?.getDuration());
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_PLAYBACK_STATE_CHANGED:
        this.currentPlayerState = arg1;
        Log.d(TAG, `state_change(),new=${arg1},old=${arg2}`);
        event.set("event", "state_change");
        event.set("new", arg1);
        event.set("old", arg2);
        this.onPlayerStateChangeLocal(arg1, arg2);
        this.eventSink?.success(event)
        break;
      case MessageType.MEDIA_INFO:
        switch (arg1) {
          case MediaInfoType.MEDIA_INFO_VIDEO_RENDERING_START:
          case MediaInfoType.MEDIA_INFO_AUDIO_RENDERING_START:
            event.set("event", "rendering_start");
            event.set("type", arg1 === MediaInfoType.MEDIA_INFO_VIDEO_RENDERING_START ? 'video' : 'audio');
            this.eventSink?.success(event)
            break;
          case MediaInfoType.MEDIA_INFO_BUFFERING_START:
          case MediaInfoType.MEDIA_INFO_BUFFERING_END:
            event.set("event", "freeze");
            event.set("value", arg1 == MediaInfoType.MEDIA_INFO_BUFFERING_START);
            this.eventSink?.success(event)
            break;
          case MediaInfoType.MEDIA_INFO_VIDEO_ROTATION_CHANGED:
            event.set("event", "rotate");
            event.set("degree", arg2);
            this.mRotate = arg2;
            this.eventSink?.success(event);
            if (this.mWidth > 0 && this.mWidth > 0) {
              this.handleEvent(MessageType.MEDIA_SET_VIDEO_SIZE, this.mWidth, this.mHeight, null);
            }
            break;
        }
        break;
      case MessageType.MEDIA_CURRENT_POSITION_UPDATE:
        event.set("event", "pos");
        event.set("pos", arg1);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_BUFFERING_UPDATE:
        event.set("event", "buffering");
        event.set("head", arg1);
        event.set("percent", arg2);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_SET_VIDEO_SIZE:
        event.set("event", "size_changed");
        if (this.mRotate == 0 || this.mRotate == 180) {
          event.set('width', arg1);
          event.set('height', arg2);
        } else {
          event.set('width', arg2);
          event.set('height', arg1);
        }
        this.eventSink?.success(event);
        this.mWidth = arg1;
        this.mHeight = arg2;
        this.updateSurfaceWH(this.mWidth, this.mHeight);
        break;
      case MessageType.MEDIA_SEEK_COMPLETE:
        event.set("event", "seek_complete");
        event.set("pos", arg1);
        event.set("err", arg2);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_ERROR:
        this.eventSink?.error(arg1.toString(), arg2.toString(), extra);
        break;
    }
  }

  setOption(category: number | undefined, key: string, value: ESObject) {
    if (typeof value === 'number') {
      if (category != undefined && category != 0) {
        this.player?.setOption(category.toString(), key, (value != undefined ? value : 0).toString());
        Log.d(TAG, `setOption1,category=${category},key=${key},value=${value}`);
      } else if (category != undefined) {
        // cat == 0, hostCategory
        this.mHostOption.addNumberOption(key, value);
      }
    } else if (typeof value === 'string') {
      if (category != undefined && category != 0) {
        this.player?.setOption(category.toString(), key, value != undefined ? value : '0');
        Log.d(TAG, `setOption2,category=${category},key=${key},value=${value}`);
      } else if (category != undefined) {
        // cat == 0, hostCategory
        this.mHostOption.addStrOption(key, value);
      } else {
        Log.d(TAG, "error arguments for setOptions");
      }
    }
  }

  getPlayId() {
    return this.id;
  }

  release() {

  }
}