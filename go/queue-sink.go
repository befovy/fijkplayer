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
