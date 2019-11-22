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
