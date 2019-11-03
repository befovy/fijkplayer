package main

import (
	fijkplayer "github.com/befovy/fijkplayer/go"
	"github.com/go-flutter-desktop/go-flutter"
)

func init() {
	// Only the init function can be tweaked by plugin maker.
	options = append(options, flutter.AddPlugin(&fijkplayer.FijkplayerPlugin{}))
}
