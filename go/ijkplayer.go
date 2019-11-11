package fijkplayer

// #cgo darwin LDFLAGS: -L ${SRCDIR}/darwin -lIjkPlayer "-Wl,-rpath,${SRCDIR}/darwin"
// #include "ijkplayer_desktop.h"
// #include <stdlib.h>
// void ijkffEventCallback(void *userdatra, int what, int arg1, int arg2, void * extra);
// void ijkffOverlayCallback(void *userdata, IjkFFOverlay *overlay);
import "C"

import (
	"github.com/go-flutter-desktop/go-flutter"
	"reflect"
	"unsafe"
)

func ijkSetLogLevel(level int) {

}

type ijkplayer struct {
	fp            *C.struct_IjkFFMediaPlayer
	eventCallback func(what int, arg1, arg2 int32, extra string)
	pixelCb       func(pixelBuffer *flutter.PixelBuffer)
}

func newIjkPlayer() *ijkplayer {
	fp := C.ijkff_create()
	return &ijkplayer{fp: fp}
}

//export ijkffOverlayCallback
func ijkffOverlayCallback(userdata unsafe.Pointer, overlay *C.struct_IjkFFOverlay) {
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
	}
}

//export ijkffEventCallback
func ijkffEventCallback(userdata unsafe.Pointer, what, arg1, arg2 C.int, extra unsafe.Pointer) {
	i := Restore(userdata).(*ijkplayer)
	ex := C.GoString((*C.char)(extra))
	i.eventCallback(int(what), int32(arg1), int32(arg2), ex)
}

func (i *ijkplayer) addEventListener(listener func(what int, arg1, arg2 int32, extra string)) {
	i.eventCallback = listener
	upt := Save(i)
	C.ijkff_set_event_cb(i.fp, upt, C.ijkff_event_cb(C.ijkffEventCallback))
}

func (i *ijkplayer) setPixelCallback(cb func(pixelBuffer *flutter.PixelBuffer)) {
	i.pixelCb = cb
	opt := Save(i)
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
}
