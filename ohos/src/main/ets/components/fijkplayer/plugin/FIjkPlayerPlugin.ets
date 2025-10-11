import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import { HashMap } from '@kit.ArkTS';
import { FIjkPlayer } from '../core/FIjkPlayer';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { getSystemVolume, ScreenOrientation, setBrightness, setOrientation, setScreenLock } from '../common/SystemUtil';
import { audio } from '@kit.AudioKit';
import { copyAssets } from '../common/AssetsCopyUtil';

const TAG = "FijkplayerPlugin";

/** FIjkPlayerPlugin **/
export default class FIjkPlayerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private playerMap: HashMap<number, FIjkPlayer> = new HashMap();
  private nextPlayId = 0;
  private binding?: FlutterPluginBinding;
  private isScreenLock: boolean = false;
  private windowBrightness: number = -1.0;
  audioManager = audio.getAudioManager();
  // 创建音频会话管理器。
  audioSessionManager: audio.AudioSessionManager = this.audioManager.getSessionManager();
  // 设置音频并发模式。
  strategy: audio.AudioSessionStrategy = {
    concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_DEFAULT
  };

  getUniqueClassName(): string {
    return "FIjkPlayerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.binding = binding;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "befovy.com/fijk");
    this.channel.setMethodCallHandler(this)

    //拷贝flutter assets资源
    copyAssets(this.binding.getApplicationContext());
  }


  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  private getNextPlayId(): number {
    return this.nextPlayId++;
  }


  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    Log.d(TAG, 'onMethodCall=' + methodName);
    switch (methodName) {
      case "createPlayer":
        if (!this.binding) {
          return;
        }
        const player: FIjkPlayer = new FIjkPlayer(this.getNextPlayId(), this.binding);
        this.playerMap.set(player.getPlayId(), player);
        result.success(player.getPlayId());
        break;
      case "releasePlayer":
        const pid: number = call.argument('pid');
        const playerFind: FIjkPlayer = this.playerMap.get(pid);
        if (playerFind) {
          playerFind.release();
          this.playerMap.remove(pid);
        }
        result.success(null);
        break;
      case "getPlatformVersion":
        result.success("OpenHarmony " + deviceInfo.sdkApiVersion);
        break;
      case "init":
        result.success(null);
        break;
      case "logLevel":
        break;
      case "setOrientationPortrait":
        if (this.binding) {
          setOrientation(this.binding.getApplicationContext(), ScreenOrientation.Portrait).then((isChanged) => {
            result.success(isChanged);
          });
        }
        break;
      case "setOrientationLandscape":
        Log.d(TAG, 'setOrientationLandscape()');
        if (this.binding) {
          setOrientation(this.binding.getApplicationContext(), ScreenOrientation.Landscape).then((isChanged) => {
            result.success(isChanged);
          });
        }
        break;
      case "setOrientationAuto":
        if (this.binding) {
          setOrientation(this.binding.getApplicationContext(), ScreenOrientation.Auto).then((isChanged) => {
            result.success(isChanged);
          });
        }
        break;
      case "setScreenOn":
        if (call.hasArgument('on') && this.binding) {
          const isOn: boolean = call.argument('on');
          this.isScreenLock = isOn;
          setScreenLock(this.binding.getApplicationContext(), isOn);
        }
        result.success(null);
        break;
      case "isScreenKeptOn":
        result.success(this.isScreenLock);
        break;
      case "brightness":
        result.success(this.windowBrightness);
        break;
      case "setBrightness":
        if (call.hasArgument('brightness') && this.binding) {
          const brightness: number = call.argument('brightness');
          this.windowBrightness = brightness;
          setBrightness(this.binding.getApplicationContext(), brightness);
        }
        result.success(null);
        break;
      case "requestAudioFocus":
        this.audioSessionManager.activateAudioSession(this.strategy).then(() => {
          Log.d(TAG, 'activateAudioSession SUCCESS');
        }).catch((err: BusinessError) => {
          Log.e(TAG, `ERROR: ${err}`);
        });
        result.success(null);
        break;
      case "releaseAudioFocus":
        this.audioSessionManager.deactivateAudioSession().then(() => {
          Log.d(TAG, 'deactivateAudioSession SUCCESS');
        }).catch((err: BusinessError) => {
          Log.e(TAG, `ERROR: ${err}`);
        });
        result.success(null);
        break;
      case "volumeDown":
        //ohos api仅系统应用支持设置音量
        break;
      case "volumeUp":
        //ohos api不支持
        break;
      case "volumeMute":
        //ohos api不支持
        break;
      case "systemVolume":
        getSystemVolume().then((volume: number) => {
          result.success(volume);
        })
        break;
      case "volumeSet":
        //ohos api不支持
        break;
      case "volUiMode":
        //设置音量ui相关
        break;
      case "onLoad":
        result.success(null);
        break;
      case "onUnload":
        result.success(null);
        break;
      default:
        Log.d(TAG, 'notImplemented(),method=' + methodName);
        result.notImplemented();
        break;
    }
  }
}