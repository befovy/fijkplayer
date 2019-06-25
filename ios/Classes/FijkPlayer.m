//
//  FijkPlayer.m
//  fijkplayer
//
//  Created by Bai Shuai on 2019/6/21.
//

#import "FijkPlayer.h"

#import "FijkQueuingEventSink.h"

#import <IJKMediaFramework/IJKMediaFramework.h>
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>


static int atomicId = 0;

@implementation FijkPlayer {
	IJKFFMediaPlayer *_ijkMediaPlayer;

    FijkQueuingEventSink *_eventSink;
	FlutterMethodChannel *_methodChannel;
	FlutterEventChannel *_eventChannel;
    
	id <FlutterPluginRegistrar> _registrar;

}


- (instancetype)initWithRegistrar:(id <FlutterPluginRegistrar>)registrar {
	self = [super init];
	if (self) {
		_registrar = registrar;
		int pid = OSAtomicIncrement32(&atomicId);
		_playerId = @(pid);

        _eventSink = [[FijkQueuingEventSink alloc] init];
		_ijkMediaPlayer = [[IJKFFMediaPlayer alloc] init];
        
        [_ijkMediaPlayer addIJKMPEventHandler:self];
		[IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_WARN];
		_methodChannel = [FlutterMethodChannel
			methodChannelWithName:[@"befovy.com/fijkplayer/" stringByAppendingString:[_playerId stringValue]]
				  binaryMessenger:[registrar messenger]];

		__block typeof(self) weakSelf = self;
		[_methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
			[weakSelf handleMethodCall:call result:result];
		}];

		//[_methodChannel setMethodCallHandler:self];
		//[_registrar addMethodCallDelegate:self channel:_methodChannel];

		_eventChannel = [FlutterEventChannel
			eventChannelWithName:[@"befovy.com/fijkplayer/event/" stringByAppendingString:[_playerId stringValue]]
				 binaryMessenger:[registrar messenger]];

		[_eventChannel setStreamHandler:self];
	}

	return self;
}

- (void)shutdown
{
	[_ijkMediaPlayer stop];
	[_ijkMediaPlayer shutdown];
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments
{
	[_eventSink setDelegate:nil];
	return nil;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
									   eventSink:(nonnull FlutterEventSink)events
{
    [_eventSink setDelegate:events];
	// TODO(@recastrodiaz): remove the line below when the race condition is resolved:
	// https://github.com/flutter/flutter/issues/21483
	// This line ensures the 'initialized' event is sent when the event
	// 'AVPlayerItemStatusReadyToPlay' fires before _eventSink is set (this function
	// onListenWithArguments is called)
	// [self sendInitialized];

	return nil;
}

- (void)onEvent4Player:(IJKFFMediaPlayer *)player withType:(int)what andArg1:(int)arg1 andArg2:(int)arg2 andExtra:(void *)extra
{
    switch (what) {
        case IJKMPET_PLAYBACK_STATE_CHANGED:
            [_eventSink success: @{@"event" : @"state_change", @"new" : @(arg1), @"old": @(arg2)}];
            break;
        case IJKMPET_BUFFERING_START:
        case IJKMPET_BUFFERING_END:
            [_eventSink success: @{@"event": @"freeze", @"value":  [NSNumber numberWithBool:what == IJKMPET_BUFFERING_START]}];
            break;
        case IJKMPET_BUFFERING_UPDATE:
            [_eventSink success: @{@"event": @"buffering",  @"head" : @(arg1), @"percent" : @(arg2)}];
            break;
        default:
            break;
    }
    
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {

	NSDictionary *argsMap = call.arguments;
	if ([@"setupSurface" isEqualToString:call.method]) {
        result(@(-1));
        //result(FlutterMethodNotImplemented);
	} else if ([@"setOption" isEqualToString:call.method]) {
		int category = [argsMap[@"cat"] intValue];
		NSString *key = argsMap[@"key"];
		if (argsMap[@"long"] != nil) {
			int64_t value = [argsMap[@"long"] longLongValue];
			[_ijkMediaPlayer setOptionIntValue:value forKey:key ofCategory:(IJKFFOptionCategory) category];
		} else if (argsMap[@"str"] != nil) {
			NSString *value = argsMap[@"str"];
			[_ijkMediaPlayer setOptionValue:value forKey:key ofCategory:(IJKFFOptionCategory) category];
		} else {
			NSLog(@"FIJKPLAYER: error arguments for setOptions");
		}
		result(nil);
	} else if ([@"setDateSource" isEqualToString:call.method]) {
		NSString *url = argsMap[@"url"];
		[_ijkMediaPlayer setDataSource:url];
		//[_ijkMediaPlayer prepareAsync];
		//[_ijkMediaPlayer start];
		result(nil);
	} else if ([@"prepareAsync" isEqualToString:call.method]) {
		[_ijkMediaPlayer prepareAsync];
		result(nil);
	} else if ([@"start" isEqualToString:call.method]) {
		[_ijkMediaPlayer start];
		result(nil);
	} else if ([@"pause" isEqualToString:call.method]) {
		[_ijkMediaPlayer pause];
		result(nil);
	} else if ([@"stop" isEqualToString:call.method]) {
		[_ijkMediaPlayer stop];
		result(nil);
	} else if ([@"reset" isEqualToString:call.method]) {
		[_ijkMediaPlayer reset];
		result(nil);
	} else {
		result(FlutterMethodNotImplemented);
	}

}


@end
