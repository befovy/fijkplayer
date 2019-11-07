package fijkplayer

// #cgo CFLAGS: -I ${SRCDIR}/darwin/IJKPlayer.framework/Headers
// #cgo LDFLAGS: -F ${SRCDIR}/darwin -framework IJKPlayer "-Wl,-rpath,${SRCDIR}/darwin"
// #include "IJKFFCMediaPlayer.h"
// #include <stdlib.h>
// void ijkmpc_event_callback(void *userdatra, int what, int arg1, int arg2, void * extra);
// void ijkmpc_overlay_callback(void *userdata, ijkmpc_overlay *overlay);
import "C"

import (
	"github.com/go-flutter-desktop/go-flutter"
	"reflect"
	"unsafe"
)

// typedef void (*IJKFFEventCb) (void *userdata, int what, int arg1, int arg2, void *extra);

// typedef void (*ijkmpc_overlay_cb) (void *userdata, ijkmpc_overlay* overlay);

func ijkSetLogLevel(level int) {

}

type ijkplayer struct {
	mpc           *C.struct_ijkmpc
	eventCallback func(what int, arg1, arg2 int32, extra string)
	pixelCb       func(pixelBuffer *flutter.PixelBuffer)
}

func newIjkplayer() *ijkplayer {
	mpc := C.ijkmpc_create()
	return &ijkplayer{mpc: mpc}
}

//export ijkmpc_overlay_callback
func ijkmpc_overlay_callback(userdata unsafe.Pointer, overlay *C.struct_ijkmpc_overlay) {
	i := Restore(userdata).(*ijkplayer)
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
		// fmt.Println("overlay.w, overlay.h ijkmpc_overlay_callback", overlay.w, overlay.h)
	}
}

//export ijkmpc_event_callback
func ijkmpc_event_callback(userdata unsafe.Pointer, what, arg1, arg2 C.int, extra unsafe.Pointer) {
	i := Restore(userdata).(*ijkplayer)
	ex := C.GoString((*C.char)(extra))
	// fmt.Println("go ijkmpc_event_callback", int32(what), int32(arg1), int32(arg2), i.eventCallback == nil)
	i.eventCallback(int(what), int32(arg1), int32(arg2), ex)

}

func (i *ijkplayer) addEventListener(listener func(what int, arg1, arg2 int32, extra string)) {
	i.eventCallback = listener
	upt := Save(i)
	C.ijkmpc_add_event_listener(i.mpc, upt, C.ijkmpc_event_cb(C.ijkmpc_event_callback))
	// C.ijkmpc_set_overlay_cb(i.mpc, opt, nil)
}

func (i *ijkplayer) setPixelCallback(cb func(pixelBuffer *flutter.PixelBuffer)) {
	i.pixelCb = cb
	opt := Save(i)
	C.ijkmpc_set_overlay_cb(i.mpc, opt, C.ijkmpc_overlay_cb(C.ijkmpc_overlay_callback))
}

func (i *ijkplayer) setIntOption(category int, key string, value int64) {
	cat := C.int(category)
	v := C.int64_t(value)
	k := C.CString(key)
	C.ijkmpc_set_int_option(i.mpc, v, k, cat)
	C.free(unsafe.Pointer(k))
}

func (i *ijkplayer) setOption(category int, key string, value string) {
	cat := C.int(category)
	v := C.CString(value)
	k := C.CString(key)
	C.ijkmpc_set_option(i.mpc, v, k, cat)
	C.free(unsafe.Pointer(k))
	C.free(unsafe.Pointer(v))
}

func (i *ijkplayer) setDataSource(url string) {
	curl := C.CString(url)
	C.ijkmpc_set_data_source(i.mpc, curl)
	C.free(unsafe.Pointer(curl))
}

func (i *ijkplayer) prepareAsync() {
	C.ijkmpc_prepare_async(i.mpc)
}

func (i *ijkplayer) start() {
	C.ijkmpc_start(i.mpc)
}

func (i *ijkplayer) pause() {
	C.ijkmpc_pause(i.mpc)
}

func (i *ijkplayer) stop() {
	C.ijkmpc_stop(i.mpc)
}

func (i *ijkplayer) reset() {
	C.ijkmpc_reset(i.mpc)
}

func (i *ijkplayer) getDuration() int64 {
	dur := C.ijkmpc_get_duration(i.mpc)
	return int64(dur)
}

func (i *ijkplayer) getCurrentPosition() int64 {
	pos := C.ijkmpc_get_current_position(i.mpc)
	return int64(pos)
}

func (i *ijkplayer) setVolume(left, right float32) {
	v := C.float((left + right) / 2)
	C.ijkmpc_set_playback_volume(i.mpc, v)
}

func (i *ijkplayer) seekTo(msec int64) {
	m := C.int64_t(msec)
	C.ijkmpc_seek_to(i.mpc, m)
}

func (i *ijkplayer) setSpeed(speed float32) {
	s := C.float(speed)
	C.ijkmpc_set_speed(i.mpc, s)
}

func (i *ijkplayer) setLoop(loop int) {
	C.ijkmpc_set_loop(i.mpc, C.int(loop))
}

func (i *ijkplayer) shutdown() {
	C.ijkmpc_shutdown(i.mpc)
}
