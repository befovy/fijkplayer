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

// #cgo darwin LDFLAGS: -lIjkPlayer
// #include "ijkplayer_desktop.h"
// #include <stdlib.h>
// void ijkffEventCallback(void *userdatra, int what, int arg1, int arg2, void * extra);
// void ijkffOverlayCallback(void *userdata, IjkFFOverlay *overlay);
import "C"

import (
	"reflect"
	"unsafe"

	"github.com/go-flutter-desktop/go-flutter"
)

func ijkSetLogLevel(level int) {
	l := C.int(level)
	C.ijkff_log_level(l)
}

func ijkGlobalInit()  {
	C.ijkff_global_init()
}

type ijkplayer struct {
	fp            *C.struct_IjkFFMediaPlayer
	eventCallback func(what int, arg1, arg2 int32, extra string)
	pixelCb       func(pixelBuffer *flutter.PixelBuffer)

	// overlay callback data
	ocbData unsafe.Pointer

	// event callback data
	ecbData unsafe.Pointer
}

func newIjkPlayer() *ijkplayer {
	const callbackVout = 2
	voutType := C.int(callbackVout)
	fp := C.ijkff_create(voutType)
	return &ijkplayer{fp: fp}
}

//export ijkffOverlayCallback
func ijkffOverlayCallback(userdata unsafe.Pointer, overlay *C.struct_IjkFFOverlay) {
	i := gpRestore(userdata).(*ijkplayer)
	if i != nil {
		var pix []uint8
		header := (*reflect.SliceHeader)(unsafe.Pointer(&pix))
		w, h := int(overlay.w), int(overlay.h)
		header.Cap = w * h * 4
		header.Len = w * h * 4
		header.Data = uintptr(unsafe.Pointer(*overlay.pixels))

		if i.pixelCb != nil {
			i.pixelCb(&flutter.PixelBuffer{Pix: pix, Height: h, Width: w})
		}
	}
}

//export ijkffEventCallback
func ijkffEventCallback(userdata unsafe.Pointer, what, arg1, arg2 C.int, extra unsafe.Pointer) {
	i := gpRestore(userdata).(*ijkplayer)
	ex := C.GoString((*C.char)(extra))
	i.eventCallback(int(what), int32(arg1), int32(arg2), ex)
}

func (i *ijkplayer) addEventListener(listener func(what int, arg1, arg2 int32, extra string)) {
	i.eventCallback = listener
	ept := gpSave(i)
	i.ecbData = ept
	C.ijkff_set_event_cb(i.fp, ept, C.ijkff_event_cb(C.ijkffEventCallback))
}

func (i *ijkplayer) setPixelCallback(cb func(pixelBuffer *flutter.PixelBuffer)) {
	i.pixelCb = cb
	opt := gpSave(i)
	i.ocbData = opt
	C.ijkff_set_overlay_cb(i.fp, opt, C.ijkff_overlay_cb(C.ijkffOverlayCallback))
}

func (i *ijkplayer) setIntOption(category int, key string, value int64) {
	cat := C.int(category)
	v := C.int64_t(value)
	k := C.CString(key)
	C.ijkff_set_int_option(i.fp, v, k, cat)
	C.free(unsafe.Pointer(k))
}

func (i *ijkplayer) setOption(category int, key string, value string) {
	cat := C.int(category)
	v := C.CString(value)
	k := C.CString(key)
	C.ijkff_set_option(i.fp, v, k, cat)
	C.free(unsafe.Pointer(k))
	C.free(unsafe.Pointer(v))
}

func (i *ijkplayer) setDataSource(url string) {
	curl := C.CString(url)
	C.ijkff_set_data_source(i.fp, curl)
	C.free(unsafe.Pointer(curl))
}

func (i *ijkplayer) prepareAsync() {
	C.ijkff_prepare_async(i.fp)
}

func (i *ijkplayer) start() {
	C.ijkff_start(i.fp)
}

func (i *ijkplayer) pause() {
	C.ijkff_pause(i.fp)
}

func (i *ijkplayer) stop() {
	C.ijkff_stop(i.fp)
}

func (i *ijkplayer) reset() {
	C.ijkff_reset(i.fp)
}

func (i *ijkplayer) getDuration() int64 {
	dur := C.ijkff_get_duration(i.fp)
	return int64(dur)
}

func (i *ijkplayer) getCurrentPosition() int64 {
	pos := C.ijkff_get_current_position(i.fp)
	return int64(pos)
}

func (i *ijkplayer) setVolume(left, right float32) {
	v := C.float((left + right) / 2)
	C.ijkff_set_playback_volume(i.fp, v)
}

func (i *ijkplayer) seekTo(msec int64) {
	m := C.int64_t(msec)
	C.ijkff_seek_to(i.fp, m)
}

func (i *ijkplayer) setSpeed(speed float32) {
	s := C.float(speed)
	C.ijkff_set_speed(i.fp, s)
}

func (i *ijkplayer) setLoop(loop int) {
	C.ijkff_set_loop(i.fp, C.int(loop))
}

func (i *ijkplayer) shutdown() {
	C.ijkff_shutdown(i.fp)
	if i.ocbData != nil {
		gpUnref(i.ocbData)
		i.ocbData = nil
	}
	if i.ecbData != nil {
		gpUnref(i.ecbData)
		i.ecbData = nil
	}
}
