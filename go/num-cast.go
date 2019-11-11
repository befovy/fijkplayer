package fijkplayer

import "reflect"

func numInt(v interface{}, defalt int) int {
	switch v.(type) {
	case int, int8, int16, int32, int64:
		return int(reflect.ValueOf(v).Int())
	case uint, uint8, uint16, uint32, uint64, uintptr:
		return int(reflect.ValueOf(v).Uint())
	}
	return defalt
}

func numInt32(v interface{}, defalt int32) int32 {
	switch v.(type) {
	case int, int8, int16, int32, int64:
		return int32(reflect.ValueOf(v).Int())
	case uint, uint8, uint16, uint32, uint64, uintptr:
		return int32(reflect.ValueOf(v).Uint())
	}
	return defalt
}

func numInt64(v interface{}, defalt int64) int64 {
	switch v.(type) {
	case int, int8, int16, int32, int64:
		return reflect.ValueOf(v).Int()
	case uint, uint8, uint16, uint32, uint64, uintptr:
		return int64(reflect.ValueOf(v).Uint())
	}
	return defalt
}

func numFloat32(v interface{}, defalt float32) float32 {
	switch v.(type) {
	case float32, float64:
		return float32(reflect.ValueOf(v).Float())
	}
	return defalt
}

func numFloat64(v interface{}, defalt float64) float64 {
	switch v.(type) {
	case float32, float64:
		return reflect.ValueOf(v).Float()
	}
	return defalt
}
