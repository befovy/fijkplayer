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

type hostOptions struct {
	intOptions map[string]int64
	strOptions map[string]string
}

func newHostOptions() *hostOptions {
	options := &hostOptions{}
	options.intOptions = make(map[string]int64)
	options.strOptions = make(map[string]string)
	return options
}

func (h *hostOptions) addIntOption(key string, v int64) {
	h.intOptions[key] = v
}

func (h *hostOptions) addStrOption(key, v string) {
	h.strOptions[key] = v
}

func (h *hostOptions) getIntOption(key string, defalt int64) int64 {
	v, ok := h.intOptions[key]
	if !ok {
		v = defalt
	}
	return v
}

func (h *hostOptions) getStrOption(key, defalt string) string {
	v, ok := h.strOptions[key]
	if !ok {
		v = defalt
	}
	return v
}
