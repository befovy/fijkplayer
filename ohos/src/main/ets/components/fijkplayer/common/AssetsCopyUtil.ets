import fs from '@ohos.file.fs';
import { Log } from '@ohos/flutter_ohos';

const TAG = 'AssetsCopyUtil'
const FILE_PREFIX = 'flutter_assets/assets';
const SEPARATOR_CHAR = '/';

/**
 * 把resources/rawfile/flutter_assets/assets下所有资源，拷贝到files目录下
 */
export function copyAssets(context: Context) {
  if (!hasRawDir(context, 'flutter_assets')) {
    log('flutter_assets not exists');
    return;
  }
  if (!hasRawDir(context, 'assets', 'flutter_assets')) {
    log('flutter_assets/assets not exists');
    return;
  }
  copyFiles(context, FILE_PREFIX);
}

function copyFiles(context: Context, parentPath: string) {
  const list: Array<string> = context.resourceManager.getRawFileListSync(parentPath);
  for (let i = list.length - 1; i >= 0; i--) {
    const filePath = parentPath + SEPARATOR_CHAR + list[i];
    if (context.resourceManager.isRawDir(filePath)) {
      copyFiles(context, filePath);
    } else {
      copyToFile(context, filePath, parentPath);
    }
  }
}

function hasRawDir(context: Context, dir: string, parentPath?: string) {
  const list: Array<string> = context.resourceManager.getRawFileListSync(parentPath ? parentPath : '');
  if (list.indexOf(dir) == -1) {
    return false;
  }
  return context.resourceManager.isRawDir(parentPath ? (parentPath + SEPARATOR_CHAR) : '' + dir);
}

/**
 *
 * @param origin rawFile下路径
 * @param target
 */
async function copyToFile(context: Context, origin: string, parentPath: string) {
  try {
    let originFile = await context.resourceManager.getRawFileContent(origin);
    const targetParent = context.filesDir + SEPARATOR_CHAR + parentPath;
    const targetPath = context.filesDir + SEPARATOR_CHAR + origin;
    if (!fs.accessSync(targetParent)) {
      fs.mkdirSync(targetParent, true);
    }
    if (fs.accessSync(targetPath)) {
      log('file is exist,path=' + origin);
      return;
    }
    let targetFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(targetFile.fd, originFile.buffer);
    log('copy file success,path=' + targetPath);
  } catch (e) {
    log('failed:origin=' + origin + ",parentPath=" + parentPath);
    log(JSON.stringify(e));
  }
}

function log(msg: string) {
  Log.d(TAG, msg);
}

/**
 * 路径转换
 * @param assetsPath assets下相对路径
 * @returns 拷贝资源的沙箱路径
 */
export function getFilePathByAssetsPath(context: Context, assetsPath: string): string {
  if (assetsPath.indexOf('/assets') != -1) {
    return context.filesDir + SEPARATOR_CHAR + 'flutter_assets' + assetsPath;
  } else {
    return context.filesDir + SEPARATOR_CHAR + FILE_PREFIX + SEPARATOR_CHAR + assetsPath;
  }
}

