##  next
--------------------------------
## 0.1.9
--------------------------------
- FijkView: fix fullscreen no state, no refresh when state change #77
- panel: fix error CircularProgressIndicator when autoPlay is false #76

## 0.1.8
--------------------------------
- FijkView: add fsFit argument, controls full screen FijkFit mode

## 0.1.7
--------------------------------
- fijkplayer: fix android volume double float cast error
- fijkplayer: fix error pause state after seeking #65

## 0.1.6
--------------------------------
- fijkplayer: update FijkVolume API, break change

## 0.1.5
--------------------------------
- ios: fix NSUrl parse error
- fijkplayer: add FijkLog with levels
- docs: english translation
- fijkplayer: new feature fijkvolume, system volume API
- ijkplayer: set default option `start-on-prepated` to 0
- iOS: fix CocoaPods use_frameworks! error

## 0.1.3
--------------------------------
- ffmpeg: enable concat and crypto protocol
- fijkplayer: add static method all() to get all fijkplayer instance
- fix: issue #31, pixelbuffer crash on iOS

## 0.1.2
--------------------------------
- fijkvalue: add video / audio render started
- fijkplayer: remove setIntOption API, use setOption instead

## 0.1.1
--------------------------------
- fix fijkpanel slider value out of range
- android: add androidx support

## 0.1.0
- update ijkplauer to f0.3.5
- fijkplayer err state and FijkException
- support playing flutter asset file 
- unit test and widget test
- pass fijkoption arguments and set player's option

## 0.0.9
--------------------------------
- update ijkplayer to f0.3.4
- add RTSP support
- decrease libary binary size

## 0.0.8
--------------------------------
- update ijkplayer to f0.3.3
- fix reset bug, #26
- Add doc website, https://fijkplayer.befovy.com
- Add diagram about FijkState, update FijkState document

## 0.0.7
--------------------------------
- Update FijkView widget tree, add FijkFit (scaling mode)
- fix pixelbuffer leak on iOS

## 0.0.6
--------------------------------
- FijkSourceType as a option argument

## 0.0.5
--------------------------------
- add FijkPanel (UI controller of video)

## 0.0.3
--------------------------------
- add more comment and update README

## 0.0.2
--------------------------------
- make iOS CocoaPods `FIJKPlayer` available

## 0.0.1
--------------------------------
- A usable music player plugin
- Draw the video frame through surface for android
