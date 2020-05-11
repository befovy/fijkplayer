---
title: fijkplayer -- Flutter plugin for ijkplayer
layout: page
permalink: /docs/zh/index.html
redirect_from:
    - /index.html
key: index
---


fijkplayer 是一个 Flutter 生态的媒体播放器，是对 [ijkplayer](https://github.com/befovy/ijkplayer) 的 Flutter 封装，支持 Android 和 iOS。
fijkplayer 使用 ijkplayer 作为播放器内核。[ijkplayer](https://github.com/bilibili/ijkplayer) 使用 ffmpeg 进行音视频解封装和解码，同时添加了 Android 和 iOS 平台特有的硬件加速解码能力。  

fijkplayer 具有和 ijkplayer 一样的播放能力，并且开箱即用，不需要使用者再去编译 ijkplayer，API易用，易于在 Flutter 项目中集成。

fijkplayer 通过纹理方式将播放器视频画面渲染接入 flutter 中，性能上优于 PlatformView 的接入方法。
fijkplayer 有内置的编译好的ffmepg 和 ijkplayer，分别托管在 jcenter 和 CocoaPods 上。

这个站点包含了大量的 fijkplayer 的文档帮助你使用以及理解 fijkplayer。

------

&nbsp; &nbsp;

开启你的 fijkplayer 之旅：

* 中文版 [开始使用](/docs/zh/install.html)  
* English Version [Getting Started](/docs/en/install.html)

<!-- * Read news, hints and tips on our [developer blog][]. -->
<!-- * Read the latest [release notes][]. -->
<!-- * Browse the library [Javadoc][]. -->
<!-- * Browse the source code for the [latest release][] and current [tip of tree][]. -->


&nbsp; &nbsp;

钉钉交流群 / 微信订阅号

<table>
  <tr>
    <td>
      <img src="/images/dingtalk.jpg"  height="200"/>
    </td>
    <td> &nbsp; &nbsp; &nbsp; </td>
    <td> &nbsp; &nbsp; &nbsp; </td>
    <td>
      <img src="/images/wechat.jpeg"  height="200"/>
    </td>
  </tr>
</table>


------

<span><small> 由于个人能力限制，文档中难免不出现纰漏。  
如果您在阅读时发现任何不当或者错误内容，请在 [github issues](https://github.com/befovy/fijkplayer/issues) 上进行指正，或直接提交 [pull request](https://github.com/befovy/fijkplayer/pulls)。 </small></span>
