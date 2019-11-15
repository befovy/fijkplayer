# fijkplayer

This Go package implements the host-side of the Flutter [fijkplayer](https://github.com/befovy/fijklayer) plugin.

## Usage

Import as:

```go
import fijkplayer "github.com/befovy/fijklayer/go"
```

Then add the following option to your go-flutter [application options](https://github.com/go-flutter-desktop/go-flutter/wiki/Plugin-info):

```go
flutter.AddPlugin(&fijkplayer.FijkplayerPlugin{}),
```
