package fijkplayer

// #cgo CFLAGS: -I ${SRCDIR}/darwin/IJKPlayer.framework/Headers
// #cgo LDFLAGS: -F ${SRCDIR}/darwin -framework IJKPlayer "-Wl,-rpath,${SRCDIR}/darwin"
// #include "IJKFFCMediaPlayer.h"
// #include <stdlib.h>
// void event_callback(void *userdatra, int what, int arg1, int arg2, void * extra);
import "C"

import (
	"fmt"
	"unsafe"
)

// typedef void (*IJKFFEventCb) (void *userdata, int what, int arg1, int arg2, void *extra);

func ijkSetLogLevel(level int) {

}

type ijkplayer struct {
	p             *C.struct_IJKFFCMediaPlayer
	eventCallback func(what, arg1, arg2 int, extra string)
}

//export event_callback
func event_callback(userdata unsafe.Pointer, what, arg1, arg2 C.int, extra unsafe.Pointer) {

	fmt.Println("event callback")
	fmt.Println("event callback")
	fmt.Println("event callback")
	i := Restore(userdata).(*ijkplayer)
	ex := C.GoString((*C.char)(extra))
	i.eventCallback((int)(what), (int)(arg1), (int)(arg2), ex)
}

func (i *ijkplayer) create() {
	i.p = C.ijkcmp_create()
}

func (i *ijkplayer) addEventListener(listener func(what, arg1, arg2 int, extra string)) {
	i.eventCallback = listener

	upt := Save(i)
	C.ijkcmp_add_event_listener(i.p, upt, C.IJKFFEventCb(C.event_callback))
}

func (i *ijkplayer) setIntOption(category int, key string, value int64) {

}

func (i *ijkplayer) setOption(category int, key string, value string) {

}

func (i *ijkplayer) setDataSource(url string) {
	curl := C.CString(url)
	C.ijkcmp_set_data_source(i.p, curl)
	C.free(unsafe.Pointer(curl))
}

func (i *ijkplayer) prepareAsync() {
	C.ijkcmp_prepareAsync(i.p)
}

func (i *ijkplayer) start() {
	C.ijkcmp_start(i.p)
}

func (i *ijkplayer) pause() {

}

func (i *ijkplayer) stop() {

}

func (i *ijkplayer) reset() {

}

func (i *ijkplayer) getCurrentPosition() int64 {
	return 0
}

func (i *ijkplayer) setVolume(left, right float32) {

}

func (i *ijkplayer) seekTo(msec int64) {

}

func (i *ijkplayer) setSpeed(speed float32) {

}
