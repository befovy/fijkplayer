import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { Log } from '@ohos/flutter_ohos';
import { audio } from '@kit.AudioKit';

const TAG = 'SystemUtil'

export async function setOrientation(context: common.Context, orientation: ScreenOrientation): Promise<boolean> {
  try {
    Log.d(TAG, 'setOrientationLandscape()');
    const windowInstance: window.Window = await window.getLastWindow(context);
    if (windowInstance) {
      await windowInstance.setPreferredOrientation(getOrientationParams(orientation));
      return true;
    }
  } catch (e) {
    Log.e(TAG, JSON.stringify(e));
    if (e['code'] == 1300002) {
      return true;
    }
  }
  return false;
}

export async function setScreenLock(context: common.Context, isLock: boolean): Promise<boolean> {
  try {
    const windowInstance: window.Window = await window.getLastWindow(context);
    await windowInstance.setWindowKeepScreenOn(isLock);
    return true;
  } catch (e) {
    Log.e(TAG, JSON.stringify(e));
  }
  return false;
}

export async function setBrightness(context: common.Context, brightness: number): Promise<boolean> {
  try {
    const windowInstance: window.Window = await window.getLastWindow(context);
    await windowInstance.setWindowBrightness(brightness);
    return true;
  } catch (e) {
    Log.e(TAG, JSON.stringify(e));
  }
  return false;
}

/**
 * 获取系统媒体音量
 * @returns
 */
export async function getSystemVolume(): Promise<number> {
  const value: audio.AudioVolumeGroupManager | undefined = await getAudioVolumeGroupManager();
  if (value) {
    return value.getVolumeSync(audio.AudioVolumeType.MEDIA);
  } else {
    return 0;
  }
}

export async function isMute(): Promise<boolean> {
  const value: audio.AudioVolumeGroupManager | undefined = await getAudioVolumeGroupManager();
  if (value) {
    return await value.isMute(audio.AudioVolumeType.MEDIA);
  } else {
    return false;
  }
}

async function getAudioVolumeGroupManager(): Promise<audio.AudioVolumeGroupManager | undefined> {
  let groupId: number = audio.DEFAULT_VOLUME_GROUP_ID;
  let audioManager = audio.getAudioManager();
  let audioVolumeManager = audioManager.getVolumeManager();
  try {
    const value: audio.AudioVolumeGroupManager = await audioVolumeManager.getVolumeGroupManager(groupId);
    return value;
  } catch (e) {
    Log.e(TAG, JSON.stringify(e));
    return undefined;
  }
}


function getOrientationParams(orientation: ScreenOrientation): window.Orientation {
  switch (orientation) {
    case ScreenOrientation.Portrait:
      return window.Orientation.PORTRAIT;
    case ScreenOrientation.Landscape:
      return window.Orientation.LANDSCAPE;
    case ScreenOrientation.Auto:
      return window.Orientation.AUTO_ROTATION;
  }
}

export enum ScreenOrientation {
  Portrait,
  Landscape,
  Auto,
}