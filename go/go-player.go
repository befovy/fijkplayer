//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

package fijkplayer

import (
	"fmt"
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"net/url"
	"os"
	"path/filepath"
	"sync/atomic"
)

var atomicId int32 = 0

const (
	idle           = 0
	initialized    = 1
	asyncPreparing = 2
	prepared       = 3
	started        = 4
	paused         = 5
	completed      = 6
	stopped        = 7
	errored        = 8
	end            = 9
)

const (
	FFP_OPT_CATEGORY_FORMAT = 1
	FFP_OPT_CATEGORY_CODEC  = 2
	FFP_OPT_CATEGORY_SWS    = 3
	FFP_OPT_CATEGORY_PLAYER = 4
	FFP_OPT_CATEGORY_SWR    = 5
)
const (
	IJKMPET_FLUSH                  = 0
	IJKMPET_ERROR                  = 100
	IJKMPET_PREPARED               = 200
	IJKMPET_COMPLETED              = 300
	IJKMPET_VIDEO_SIZE_CHANGED     = 400
	IJKMPET_SAR_CHANGED            = 401
	IJKMPET_VIDEO_RENDERING_START  = 402
	IJKMPET_AUDIO_RENDERING_START  = 403
	IJKMPET_VIDEO_ROTATION_CHANGED = 404
	IJKMPET_BUFFERING_START        = 500
	IJKMPET_BUFFERING_END          = 501
	IJKMPET_BUFFERING_UPDATE       = 502
	IJKMPET_POSITION_UPDATE		   = 510
	IJKMPET_PLAYBACK_STATE_CHANGED = 700
)

type FijkPlayer struct {
	id     int32
	state  int32
	rotate int32
	width  int32
	height int32

	ijk *ijkplayer

	hostOptions   *hostOptions
	lastBuffer    *flutter.PixelBuffer
	pixels        *flutter.PixelBuffer
	texture       flutter.Texture
	texRegistry   *flutter.TextureRegistry
	methodChannel *plugin.MethodChannel
	eventChannel  *plugin.EventChannel
	sink          *queueEventSink
}

// OnListen handles a request to set up an event stream.
func (f *FijkPlayer) OnListen(arguments interface{}, sink *plugin.EventSink) {
	f.sink.setSink(sink)
}

// OnCancel handles a request to tear down the most recently created event
// stream.
func (f *FijkPlayer) OnCancel(arguments interface{}) {
	f.sink.setSink(nil)
}

func (f *FijkPlayer) initPlayer(messenger plugin.BinaryMessenger, tex *flutter.TextureRegistry) {

	f.id = atomic.AddInt32(&atomicId, 1)
	f.state = idle
	f.texRegistry = tex
	f.texture.ID = -1
	f.sink = &queueEventSink{}

	f.hostOptions = newHostOptions()
	f.ijk = newIjkPlayer()
	f.ijk.addEventListener(f.eventListener)
	f.ijk.setOption(FFP_OPT_CATEGORY_PLAYER, "overlay-format", "fcc-rgba")
	f.ijk.setIntOption(FFP_OPT_CATEGORY_PLAYER,"enable-position-notify", 1)

	f.methodChannel = plugin.NewMethodChannel(messenger,
		fmt.Sprintf("befovy.com/fijkplayer/%d", f.id),
		plugin.StandardMethodCodec{})
	f.methodChannel.HandleFunc("setupSurface", f.handleSetupSurface)
	f.methodChannel.HandleFunc("setOption", f.handleSetOption)
	f.methodChannel.HandleFunc("applyOptions", f.handleApplyOptions)
	f.methodChannel.HandleFunc("setDataSource", f.handleSetDataSource)
	f.methodChannel.HandleFunc("prepareAsync", f.handlePrepareAsync)
	f.methodChannel.HandleFunc("start", f.handleStart)
	f.methodChannel.HandleFunc("pause", f.handlePause)
	f.methodChannel.HandleFunc("stop", f.handleStop)
	f.methodChannel.HandleFunc("reset", f.handleReset)
	f.methodChannel.HandleFunc("getCurrentPosition", f.handleGetCurrentPosition)
	f.methodChannel.HandleFunc("setVolume", f.handleSetVolume)
	f.methodChannel.HandleFunc("seekTo", f.handleSeekTo)
	f.methodChannel.HandleFunc("setLoop", f.handleSetLoop)
	f.methodChannel.HandleFunc("setSpeed", f.handleSetSpeed)
	f.methodChannel.HandleFunc("snapshot", f.handleSnapshot)

	f.eventChannel = plugin.NewEventChannel(messenger,
		fmt.Sprintf("befovy.com/fijkplayer/event/%d", f.id),
		plugin.StandardMethodCodec{})
	f.eventChannel.Handle(f)
}

func (f *FijkPlayer) getId() int32 {
	return f.id
}

func (f *FijkPlayer) eventListener(what int, arg1, arg2 int32, extra string) {
	f.handleEvent(what, arg1, arg2, extra)
}

func (f *FijkPlayer) pixelReceived(buffer *flutter.PixelBuffer) {
	//pix := make([]uint8, buffer.Width * buffer.Height *4)
	//fmt.Println(buffer)
	//spew.Dump(buffer)
	//copy(pix, buffer.Pix)
	//f.pixels = &flutter.PixelBuffer{Height: buffer.Height,
	//	Width:buffer.Width,Pix:pix}
	f.pixels = buffer
	err := f.texture.FrameAvailable()
	if err != nil {
		fmt.Println("pixelReceived", err)
	}
}

func (f *FijkPlayer) handleSetupSurface(arguments interface{}) (reply interface{}, err error) {
	println("setup surface", f.texRegistry)
	if f.texRegistry != nil && f.texture.ID < 0{
		f.texture = f.texRegistry.NewTexture()
		err := f.texture.Register(f.textureHanler)
		if err != nil {
			fmt.Println(err.Error())
		}
		fmt.Printf("setupsurface tid:%d\n", f.texture.ID)
		f.ijk.setPixelCallback(f.pixelReceived)
	}
	return f.texture.ID, nil
}

func (f *FijkPlayer) handleSetOption(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	cat := -1
	key := ""
	if category, ok := args["cat"]; ok {
		cat = numInt(category, -1)
	}
	if keykey, ok := args["key"]; ok {
		key = keykey.(string)
	}
	if f.ijk != nil && cat >= 0 && len(key) > 0 {
		if intValue, exist := args["long"]; exist {
			if cat != 0 {
				f.ijk.setIntOption(cat, key, numInt64(intValue, 0))
			} else {
				f.hostOptions.addIntOption(key, numInt64(intValue, 0))
			}
		} else if strValue, exist := args["str"]; exist {
			if cat != 0 {
				f.ijk.setOption(cat, key, strValue.(string))
			} else {
				f.hostOptions.addStrOption(key, strValue.(string))
			}
		}
	}
	return nil, nil
}

func (f *FijkPlayer) handleApplyOptions(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	for o, option := range args {
		cat, oOk := o.(int)
		optionMap, optionMapOk := option.(map[interface{}]interface{})
		if oOk && optionMapOk && f.ijk != nil {
			for k, v := range optionMap {
				key, kOk := k.(string)
				intValue, intValueOk := v.(int64)
				strValue, strValueOk := v.(string)
				if kOk && intValueOk {
					if cat != 0 {
						f.ijk.setIntOption(cat, key, intValue)
					} else {
						f.hostOptions.addIntOption(key, intValue)
					}
				} else if kOk && strValueOk {
					if cat != 0 {
						f.ijk.setOption(cat, key, strValue)
					} else {
						f.hostOptions.addStrOption(key, strValue)
					}
				}
			}
		}
	}
	return nil, nil
}

func (f *FijkPlayer) handleSetDataSource(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	source, ok := args["url"]
	if ok {
		if urlStr, urlStrOk := source.(string); urlStrOk {
			u, err := url.Parse(urlStr)
			if err == nil && u != nil && u.Scheme == "asset" {
				ex, err := os.Executable()
				if err == nil {
					exPath := filepath.Dir(ex)
					urlStr = filepath.Join(exPath, "flutter_assets", u.Path)
				}
			}
			f.ijk.setDataSource(urlStr)
		}
	}
	f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, initialized, -1, nil)
	return nil, nil
}

func (f *FijkPlayer) handlePrepareAsync(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.prepareAsync()
	}
	f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, asyncPreparing, -1, nil)
	return nil, nil
}
func (f *FijkPlayer) handleStart(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.start()
	}
	return nil, nil
}

func (f *FijkPlayer) handlePause(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.pause()
	}
	return nil, nil
}

func (f *FijkPlayer) handleStop(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.stop()
	}
	f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, stopped, -1, nil)
	return nil, nil
}

func (f *FijkPlayer) handleReset(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.reset()
	}
	f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, idle, -1, nil)
	return nil, nil
}

func (f *FijkPlayer) handleGetCurrentPosition(arguments interface{}) (reply interface{}, err error) {
	var pos int64 = 0
	if f.ijk != nil {
		pos = f.ijk.getCurrentPosition()
	}
	return pos, nil
}

func (f *FijkPlayer) handleSetVolume(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	vol, ok := args["volume"]
	if ok {
		volume := numFloat32(vol, 1.0)
		f.ijk.setVolume(volume, volume)
	}
	return nil, nil
}

func (f *FijkPlayer) handleSeekTo(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	msec, ok := args["msec"]
	if ok {
		if f.state == completed {
			f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, paused, -1, nil)
		}
		msecInt64 := numInt64(msec, 0)
		f.ijk.seekTo(msecInt64)
	}
	return nil, nil
}

func (f *FijkPlayer) handleSetLoop(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	loop, ok := args["loop"]
	if ok {
		loopInt := numInt(loop, 1)
		f.ijk.setLoop(loopInt)
	}
	return nil, nil
}

func (f *FijkPlayer) handleSetSpeed(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	speed, ok := args["speed"]
	if ok {
		speedFloat32 := numFloat32(speed, 1.0)
		f.ijk.setSpeed(speedFloat32)
	}
	return nil, nil
}

func (f* FijkPlayer) handleSnapshot(arguments interface{}) (reply interface{}, err error)  {
	_ = f.methodChannel.InvokeMethod("_onSnapshot", "not support")
	return nil, nil
}

func (f *FijkPlayer) textureHanler(width, height int) (bool, *flutter.PixelBuffer) {
	// t := time.Now()
	// fmt.Println(t.Unix(), "textureHanler", width, height)
	//return true, &flutter.PixelBuffer{Width:16, Height:16,Pix: pix}
	return true, f.pixels
}

func (f *FijkPlayer) release() {

	f.handleEvent(IJKMPET_PLAYBACK_STATE_CHANGED, end, f.state, nil)

	if f.ijk != nil {
		f.ijk.shutdown()
		f.ijk = nil
	}
	if f.texRegistry != nil {
		f.texRegistry = nil
		fmt.Printf("texture %d\n", f.texture.ID)
		if f.texture.ID >= 0 {
			err := f.texture.UnRegister()
			if err != nil {
				fmt.Printf("unRegister %s\n", err.Error())
			}
			f.texture.ID = -1
		}
	}

	f.methodChannel.ClearAllHandle()
	f.methodChannel.CatchAllHandleFunc(nil)
	f.methodChannel = nil
	f.sink.setSink(nil)
	f.eventChannel.Handle(nil)
	f.eventChannel = nil
}

func isPlayable(state int32) bool {
	return state == started || state == paused || state == completed || state == prepared
}

func onStateChanged(newState int32, oldState int32) {
	fpg := fplugin
	if fpg != nil {
		if newState == started && oldState != started {
			fpg.onPlayingChange(1)
		} else if newState != started && oldState == started {
			fpg.onPlayingChange(-1)
		}

		if isPlayable(newState) && !isPlayable(oldState) {
			fpg.onPlayableChange(1)
		} else if !isPlayable(newState) && isPlayable(oldState) {
			fpg.onPlayableChange(-1)
		}
	}
}

func (f *FijkPlayer) handleEvent(what int, arg1, arg2 int32, extra interface{}) {
	event := make(map[interface{}]interface{})

	switch what {
	case IJKMPET_PREPARED:
		event["event"] = "prepared"
		event["duration"] = f.ijk.getDuration()
		f.sink.success(event)
		break
	case IJKMPET_PLAYBACK_STATE_CHANGED:
		f.state = arg1
		event["event"] = "state_change"
		event["new"] = arg1
		event["old"] = arg2
		f.sink.success(event)
		onStateChanged(arg1, arg2)
		break
	case IJKMPET_VIDEO_RENDERING_START,
		IJKMPET_AUDIO_RENDERING_START:
		event["event"] = "rendering_start"
		if what == IJKMPET_VIDEO_RENDERING_START {
			event["type"] = "video"
		} else {
			event["type"] = "audio"
		}
		f.sink.success(event)
		break
	case IJKMPET_BUFFERING_START,
		IJKMPET_BUFFERING_END:
		event["event"] = "freeze"
		event["value"] = what == IJKMPET_BUFFERING_START
		f.sink.success(event)
		break
	case IJKMPET_BUFFERING_UPDATE:
		event["event"] = "buffering"
		event["head"] = arg1
		event["percent"] = arg2
		f.sink.success(event)
		break
	case IJKMPET_POSITION_UPDATE:
		event["event"] = "pos";
		event["pos"] = arg1;
		f.sink.success(event);
		break;
	case IJKMPET_VIDEO_ROTATION_CHANGED:
		event["event"] = "rotate"
		event["degree"] = arg1
		f.sink.success(event)
		f.rotate = arg1
		if f.height > 0 && f.width > 0 {
			f.handleEvent(IJKMPET_VIDEO_SIZE_CHANGED, f.width, f.height, nil)
		}
		break
	case IJKMPET_VIDEO_SIZE_CHANGED:
		event["event"] = "size_changed"
		if f.rotate == 0 || f.rotate == 90 {
			event["width"] = arg1
			event["height"] = arg2
			f.sink.success(event)
		} else if f.rotate == 90 || f.rotate == 270 {
			event["width"] = arg2
			event["height"] = arg1
			f.sink.success(event)
		}
		f.width = arg1
		f.height = arg2
		break
	case IJKMPET_ERROR:
		str := ""
		if s, ok := extra.(string); ok {
			str = s
		}
		f.sink.onError(fmt.Sprintf("%d", arg1), str, arg2)
		break
	default:
		break
	}
}
