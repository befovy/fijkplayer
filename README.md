# fijkplayer

A Flutter media player plugin for iOS and android based on [ijkplayer](https://github.com/befovy/ijkplayer)


*Note*: This plugin is still under development, and some APIs might not be available yet.
[Feedback welcome](https://github.com/befovy/fijkplayer/issues) and
[Pull Requests](https://github.com/befovy/fijkplayer/pulls) are most welcome!

## Installation

First, add `fijkplayer` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### iOS

Warning: The video player is not functional on iOS simulators. An iOS device must be used during development/testing.


### Android


Ensure the following permission is present in your Android Manifest file if you want to play a network stream, 
located in `<project root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

The example in this plugin project adds it, so it may already be there.



## Demo Screenshots

iOS screenshots
<div>
<img src="https://user-images.githubusercontent.com/51129600/61178868-abefcc00-a629-11e9-851f-f4b2ab0028fb.jpeg" height="300px" alt="ios_input" >
&nbsp;	&nbsp;	&nbsp;	
<img src="https://user-images.githubusercontent.com/51129600/61178869-abefcc00-a629-11e9-8b15-872d8cd207b9.jpeg" height="300px" alt="ios_video" >
</div>

android screenshots

<div>
<img src="https://user-images.githubusercontent.com/51129600/61178866-ab573580-a629-11e9-8019-77a400998531.jpeg" height="300px" alt="android_home" >
&nbsp;	&nbsp;	&nbsp;	
<img src="https://user-images.githubusercontent.com/51129600/61178867-ab573580-a629-11e9-8829-8a37efb39d7d.jpeg" height="300px" alt="android_video" >
</div>
