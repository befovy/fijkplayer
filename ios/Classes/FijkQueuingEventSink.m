//
//  FijkQueuingEventSink.m
//  fijkplayer
//
//  Created by Befovy on 2019/6/25.
//

#import "FijkQueuingEventSink.h"

@implementation FijkQueuingEventSink {
    NSMutableArray *_eventQueue;
    BOOL _done;
    FlutterEventSink _delegate;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegate = nil;
        _done = false;
        _eventQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)maybeFlush {
    if (_delegate == nil)
        return;

    for (NSObject *event in _eventQueue) {
        _delegate(event);
    }
    [_eventQueue removeAllObjects];
}

- (void)enqueue:(const NSObject *)event {
    if (_done)
        return;
    [_eventQueue addObject:event];
}

- (void)setDelegate:(FlutterEventSink)sink {
    _delegate = sink;
    [self maybeFlush];
}

- (void)endOfStream {
    [self enqueue:FlutterEndOfEventStream];
    [self maybeFlush];
    _done = TRUE;
}

- (void)error:(NSString *)code
      message:(NSString *)message
      details:(NSObject *)details {
    [self enqueue:[FlutterError errorWithCode:code
                                      message:message
                                      details:details]];
    [self maybeFlush];
}

- (void)success:(NSObject *)event {
    [self enqueue:event];
    [self maybeFlush];
}

@end
