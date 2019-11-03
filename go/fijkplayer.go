package fijkplayer

import (
	"fmt"
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
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

type FijkPlayer struct {
	id    int32
	state int

	ijk *ijkplayer

	texture       flutter.Texture
	texRegistry   *flutter.TextureRegistry
	methodChannel *plugin.MethodChannel
	eventChannel  *plugin.EventChannel
	sink          *plugin.EventSink
}

// OnListen handles a request to set up an event stream.
func (f *FijkPlayer) OnListen(arguments interface{}, sink *plugin.EventSink) {
	f.sink = sink
}

// OnCancel handles a request to tear down the most recently created event
// stream.
func (f *FijkPlayer) OnCancel(arguments interface{}) {
	f.sink = nil
}

func (f *FijkPlayer) initPlayer(messenger plugin.BinaryMessenger, tex *flutter.TextureRegistry) {


	f.id = atomic.AddInt32(&atomicId, 1)
	f.state = idle
	f.texRegistry = tex

	f.ijk = &ijkplayer{}
	f.ijk.create()
	f.ijk.addEventListener(f.eventListener)
	f.methodChannel = plugin.NewMethodChannel(messenger,
		fmt.Sprintf("befovy.com/fijkplayer/%d", f.id),
		plugin.StandardMethodCodec{})
	f.methodChannel.HandleFunc("setupSurface", f.handleSetupSurface)
	f.methodChannel.HandleFunc("setOption", f.handleSetOption)
	f.methodChannel.HandleFunc("applyOptions", f.handleApplyOptions)
	f.methodChannel.HandleFunc("setDateSource", f.handleSetDataSource)
	f.methodChannel.HandleFunc("prepareAsync", f.handlePrepareAsync)
	f.methodChannel.HandleFunc("start", f.handleStart)
	f.methodChannel.HandleFunc("pause", f.handlePause)
	f.methodChannel.HandleFunc("stop", f.handleStop)
	f.methodChannel.HandleFunc("reset", f.handleReset)
	// todo method handler

	f.eventChannel = plugin.NewEventChannel(messenger,
		fmt.Sprintf("befovy.com/fijkplayer/event/%d", f.id),
		plugin.StandardMethodCodec{})
	f.eventChannel.Handle(f)
}

func (f *FijkPlayer) getId() int32 {
	return f.id
}

func (f *FijkPlayer) eventListener(what , arg1, arg2 int, extra string)  {

	fmt.Printf("f event listener %d %d %d\n" , what, arg1, arg2)
}

func (f *FijkPlayer) handleSetupSurface(arguments interface{}) (reply interface{}, err error) {
	if f.texRegistry != nil {
		f.texture = f.texRegistry.NewTexture()
		err := f.texture.Register(f.textureHanler)
		if err != nil {
			fmt.Println(err.Error())
		}
		fmt.Printf("setupsurface tid:%d\n", f.texture.ID)
	}

	return f.texture.ID, nil
}

func (f *FijkPlayer) handleSetOption(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	cat := -1
	key := ""
	if category, ok := args["cat"]; ok {
		cat = int(category.(int32))
	}
	if keykey, ok := args["key"]; ok {
		key = keykey.(string)
	}
	if f.ijk != nil && cat >= 0 && len(key) > 0 {
		if intValue, exist := args["long"]; exist {
			f.ijk.setIntOption(cat, key, int64(intValue.(int32)))
		} else if strValue, exist := args["str"]; exist {
			f.ijk.setOption(cat, key, strValue.(string))
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
					f.ijk.setIntOption(cat, key, intValue)
				} else if kOk && strValueOk {
					f.ijk.setOption(cat, key, strValue)
				}
			}
		}
	}
	return nil, nil
}

func (f *FijkPlayer) handleSetDataSource(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	url, ok := args["url"]
	if ok {
		if urlStr, urlStrOk := url.(string); urlStrOk {
			f.ijk.setDataSource(urlStr)
		}
	}
	return nil, nil
}

func (f *FijkPlayer) handlePrepareAsync(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.prepareAsync()
	}
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
	return nil, nil
}

func (f *FijkPlayer) handleReset(arguments interface{}) (reply interface{}, err error) {
	if f.ijk != nil {
		f.ijk.reset()
	}
	return nil, nil
}

func (f *FijkPlayer) handleGetCurrentPosition(arguments interface{}) (reply interface{}, err error) {
	var pos int64 = 0
	if f.ijk != nil {
		pos = f.ijk.getCurrentPosition()
	}
	return pos, nil
}

func (f *FijkPlayer) textureHanler(width, height int) (bool, *flutter.PixelBuffer) {

	return false, nil
}

func (f *FijkPlayer) release() {

	if f.texRegistry != nil {
		f.texRegistry = nil
		fmt.Printf("texture %d\n", f.texture.ID)
		//err := f.texture.UnRegister()
		//if err != nil {
		//	fmt.Printf("unRegister %s\n", err.Error())
		//}
		f.texture.ID = -1
	}
}

func isPlayable(state int) bool {
	return state == started || state == paused || state == completed || state == prepared
}

func onStateChanged(newState int, oldState int) {
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

func (f *FijkPlayer) handleEvent(what, arg1, arg2 int, extra interface{}) {
	event := make(map[interface{}]interface{})

	// todo
	switch what {
	case 100:
		event["event"] = "prepared"
		break
	}
}
