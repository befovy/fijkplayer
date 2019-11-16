# Changelog


## [0.2.1](https://github.com/befovy/fijkplayer/compare/v0.2.0...v0.2.1) (2019-11-16)
--------------------------------

* fix: wrong screen orientation after exit full screen mode on Android ([#108](https://github.com/befovy/fijkplayer/issues/108)) ([d0fea2c](https://github.com/befovy/fijkplayer/commit/d0fea2c11117dd4b12bdcd386a4d29cfdce40bf4)), closes [#73](https://github.com/befovy/fijkplayer/issues/73)

## [0.2.0](https://github.com/befovy/fijkplayer/compare/v0.1.10...v0.2.0) (2019-11-15)
--------------------------------

* go-flutter desktop version support ([#107](https://github.com/befovy/fijkplayer/issues/107)) ([966caef](https://github.com/befovy/fijkplayer/commit/966caef0251aecca14aa3d36c822316bb0fb0fe0))
* fix restart timer when touch slider  ([#104](https://github.com/befovy/fijkplayer/issues/104)) ([765e2e6](https://github.com/befovy/fijkplayer/commit/765e2e61fd95d94ae4fed44e2b7e700e6c57920e))


## [0.1.10](https://github.com/befovy/fijkplayer/compare/v0.1.9...v0.1.10) (2019-11-15)
--------------------------------

* new API, FijkVolume.getVol() ([#100](https://github.com/befovy/fijkplayer/issues/100)) ([dd57cea](https://github.com/befovy/fijkplayer/commit/dd57cea4870a909cbbec71a4cc127fdbefe9cf1f))
* set datasource member variable when setDataSource ([20f94de](https://github.com/befovy/fijkplayer/commit/20f94deb0bb561e4fc0127eb615200e26b46f6c1))
* proguard for android class ([1f85f28](https://github.com/befovy/fijkplayer/commit/1f85f28728cb89e48576b9791909860728160751)), closes [#98](https://github.com/befovy/fijkplayer/issues/98)
* update doc error method name. FijkVolume.setUIMode ([#102](https://github.com/befovy/fijkplayer/issues/102)) ([c33cc11](https://github.com/befovy/fijkplayer/commit/c33cc11d5676fb6b411f9b7be7f14850ea662ecc))

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
