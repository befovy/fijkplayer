package fijkplayer

// #include <stdlib.h>
import "C"

import (
	"sync"
	"unsafe"
)

// https://github.com/mattn/go-pointer/blob/master/pointer.go
// https://github.com/golang/proposal/blob/master/design/12416-cgo-pointers.md

var (
	mutex sync.Mutex
	store = map[unsafe.Pointer]interface{}{}
)

func Save(v interface{}) unsafe.Pointer {
	if v == nil {
		return nil
	}

	// Generate real fake C pointer.
	// This pointer will not store any data, but will bi used for indexing purposes.
	// Since Go doest allow to cast dangling pointer to unsafe.Pointer, we do rally allocate one byte.
	// Why we need indexing, because Go doest allow C code to store pointers to Go data.
	var ptr unsafe.Pointer = C.malloc(C.size_t(1))
	if ptr == nil {
		panic("can't allocate 'cgo-pointer hack index pointer': ptr == nil")
	}

	mutex.Lock()
	store[ptr] = v
	mutex.Unlock()

	return ptr
}

func Restore(ptr unsafe.Pointer) (v interface{}) {
	if ptr == nil {
		return nil
	}

	mutex.Lock()
	v = store[ptr]
	mutex.Unlock()
	return
}

func Unref(ptr unsafe.Pointer) {
	if ptr == nil {
		return
	}

	mutex.Lock()
	delete(store, ptr)
	mutex.Unlock()

	C.free(ptr)
}
