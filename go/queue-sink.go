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
	"container/list"
	"github.com/go-flutter-desktop/go-flutter/plugin"
)

type queueEventSink struct {
	sink       *plugin.EventSink
	eventQueue list.List
	done       bool
}

func (q *queueEventSink) setSink(sink *plugin.EventSink) {
	q.sink = sink
	q.maybeFlush()
}

func (q *queueEventSink) endOfStream() {
	q.enqueue(endOfStreamEvent{})
	q.maybeFlush()
	q.done = true
}

func (q *queueEventSink) onError(code, msg string, detail interface{}) {
	q.enqueue(errorEvent{code, msg, detail})
	q.maybeFlush()
}

func (q *queueEventSink) success(event interface{}) {
	q.enqueue(event)
	q.maybeFlush()
}

func (q *queueEventSink) enqueue(event interface{}) {
	if q.done {
		return
	}
	q.eventQueue.PushBack(event)
}

func (q *queueEventSink) maybeFlush() {
	if q.sink == nil {
		return
	}
	for {
		e := q.eventQueue.Front()
		if e == nil {
			break
		}
		q.eventQueue.Remove(e)

		event := e.Value

		var ok bool = false
		if _, ok = event.(endOfStreamEvent); ok {
			q.sink.EndOfStream()
		} else if err, ok := event.(errorEvent); ok {
			q.sink.Error(err.code, err.msg, err.detail)
		} else {
			q.sink.Success(event)
		}
	}

}

type endOfStreamEvent struct {
}

type errorEvent struct {
	code   string
	msg    string
	detail interface{}
}
