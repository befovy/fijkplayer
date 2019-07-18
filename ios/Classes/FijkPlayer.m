//
//  FijkPlayer.m
//  fijkplayer
//
//  Created by Befovy on 2019/6/21.
//

#import "FijkPlayer.h"

#import "FijkQueuingEventSink.h"

#import <FIJKPlayer/IJKFFMediaPlayer.h>
#import <FIJKPlayer/IJKFFMoviePlayerController.h>
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>

static int atomicId = 0;

@implementation FijkPlayer {
    IJKFFMediaPlayer *_ijkMediaPlayer;

    FijkQueuingEventSink *_eventSink;
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;

    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
    CVPixelBufferRef _cachePixelBufer;
    NSRecursiveLock *_cvPbLock;

    int _pid;
    int64_t _vid;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        int pid = OSAtomicIncrement32(&atomicId);
        _playerId = @(pid);
        _pid = pid;
        _eventSink = [[FijkQueuingEventSink alloc] init];
        _ijkMediaPlayer = [[IJKFFMediaPlayer alloc] init];
        _cvPbLock = [[NSRecursiveLock alloc] init];
        _cachePixelBufer = nil;
        _vid = -1;

        [_ijkMediaPlayer addIJKMPEventHandler:self];

        [_ijkMediaPlayer setOptionIntValue:1
                                    forKey:@"videotoolbox"
                                ofCategory:kIJKFFOptionCategoryPlayer];
        [_ijkMediaPlayer setOptionValue:@"fcc-bgra"
                                 forKey:@"overlay-format"
                             ofCategory:kIJKFFOptionCategoryPlayer];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
        _methodChannel = [FlutterMethodChannel
            methodChannelWithName:[@"befovy.com/fijkplayer/"
                                      stringByAppendingString:[_playerId
                                                                  stringValue]]
                  binaryMessenger:[registrar messenger]];

        __block typeof(self) weakSelf = self;
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall *call,
                                               FlutterResult result) {
          [weakSelf handleMethodCall:call result:result];
        }];

        //[_methodChannel setMethodCallHandler:self];
        //[_registrar addMethodCallDelegate:self channel:_methodChannel];

        _eventChannel = [FlutterEventChannel
            eventChannelWithName:[@"befovy.com/fijkplayer/event/"
                                     stringByAppendingString:[_playerId
                                                                 stringValue]]
                 binaryMessenger:[registrar messenger]];

        [_eventChannel setStreamHandler:self];
    }

    return self;
}

- (void)shutdown {
    [_ijkMediaPlayer stop];
    [_ijkMediaPlayer shutdown];
    if (_vid >= 0) {
        [_textureRegistry unregisterTexture:_vid];
        _vid = -1;
        _textureRegistry = nil;
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    [_eventSink setDelegate:nil];
    return nil;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:
                                           (nonnull FlutterEventSink)events {
    [_eventSink setDelegate:events];
    return nil;
}

- (void)display_pixelbuffer:(CVPixelBufferRef)pixelbuffer {
    [_cvPbLock lock];
    if (_cachePixelBufer != nil)
        CVBufferRelease(_cachePixelBufer);

    // NSLog(@"display_pixelbuffer %@ %d", pixelbuffer, (int)_vid);
    if (pixelbuffer != nil) {
        _cachePixelBufer = CVBufferRetain(pixelbuffer);
        if (_vid >= 0) {
            [_textureRegistry textureFrameAvailable:_vid];
        }
    }
    [_cvPbLock unlock];
}

- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    [_cvPbLock lock];
    CVPixelBufferRef buffer = _cachePixelBufer;

    if (buffer)
        CFRetain(buffer);
    [_cvPbLock unlock];
    return buffer;
}

- (NSNumber *)setupSurface {
    if (_vid < 0) {
        _textureRegistry = [_registrar textures];
        int64_t vid = [_textureRegistry registerTexture:self];
        _vid = vid;
        [_ijkMediaPlayer setupCVPixelBufferView:self];
    }
    return [NSNumber numberWithLongLong:_vid];
}

- (void)onEvent4Player:(IJKFFMediaPlayer *)player
              withType:(int)what
               andArg1:(int)arg1
               andArg2:(int)arg2
              andExtra:(void *)extra {
    switch (what) {
    case IJKMPET_PREPARED: {
        long duration = [_ijkMediaPlayer getDuration];
        [_eventSink
            success:@{@"event" : @"prepared", @"duration" : @(duration)}];
    } break;
    case IJKMPET_PLAYBACK_STATE_CHANGED:
        [_eventSink success:@{
            @"event" : @"state_change",
            @"new" : @(arg1),
            @"old" : @(arg2)
        }];
        break;
    case IJKMPET_BUFFERING_START:
    case IJKMPET_BUFFERING_END:
        [_eventSink success:@{
            @"event" : @"freeze",
            @"value" : [NSNumber numberWithBool:what == IJKMPET_BUFFERING_START]
        }];
        break;
    case IJKMPET_BUFFERING_UPDATE:
        [_eventSink success:@{
            @"event" : @"buffering",
            @"head" : @(arg1),
            @"percent" : @(arg2)
        }];
        break;
    case IJKMPET_VIDEO_SIZE_CHANGED:
        [_eventSink success:@{
            @"event" : @"size_changed",
            @"width" : @(arg1),
            @"height" : @(arg2)
        }];
    default:
        break;
    }
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {

    NSDictionary *argsMap = call.arguments;
    if ([@"setupSurface" isEqualToString:call.method]) {
        result([self setupSurface]);
    } else if ([@"setOption" isEqualToString:call.method]) {
        int category = [argsMap[@"cat"] intValue];
        NSString *key = argsMap[@"key"];
        if (argsMap[@"long"] != nil) {
            int64_t value = [argsMap[@"long"] longLongValue];
            [_ijkMediaPlayer setOptionIntValue:value
                                        forKey:key
                                    ofCategory:(IJKFFOptionCategory)category];
        } else if (argsMap[@"str"] != nil) {
            NSString *value = argsMap[@"str"];
            [_ijkMediaPlayer setOptionValue:value
                                     forKey:key
                                 ofCategory:(IJKFFOptionCategory)category];
        } else {
            NSLog(@"FIJKPLAYER: error arguments for setOptions");
        }
        result(nil);
    } else if ([@"setDateSource" isEqualToString:call.method]) {
        NSString *url = argsMap[@"url"];
        [_ijkMediaPlayer setDataSource:url];
        result(nil);
    } else if ([@"prepareAsync" isEqualToString:call.method]) {
        [_ijkMediaPlayer prepareAsync];
        result(nil);
    } else if ([@"start" isEqualToString:call.method]) {
        int ret = [_ijkMediaPlayer start];
        NSLog(@"start start %d", ret);
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
    } else if ([@"getCurrentPosition" isEqualToString:call.method]) {
        long pos = [_ijkMediaPlayer getCurrentPosition];
        // [_eventSink success:@{@"event" : @"current_pos", @"pos" : @(pos)}];
        result(@(pos));
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
