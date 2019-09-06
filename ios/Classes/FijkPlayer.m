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
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static atomic_int atomicId = 0;

@implementation FijkPlayer {
    IJKFFMediaPlayer *_ijkMediaPlayer;

    FijkQueuingEventSink *_eventSink;
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;

    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
    //CVPixelBufferRef _cachePixelBufer;
    //CVPixelBufferRef _Atomic _pixelBuffer;

    CVPixelBufferRef volatile _latestPixelBuffer;

    int _state;
    int _pid;
    int64_t _vid;
}

static const int idle = 0;
static const int initialized = 1;
static const int asyncPreparing = 2;
static const int __attribute__((unused)) prepared = 3;
static const int __attribute__((unused)) started = 4;
static const int paused = 5;
static const int completed = 6;
static const int stopped = 7;
static const int __attribute__((unused)) error = 8;
static const int end = 9;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
        _pid = pid;
        _eventSink = [[FijkQueuingEventSink alloc] init];
        _ijkMediaPlayer = [[IJKFFMediaPlayer alloc] init];
        //_cachePixelBufer = nil;
        //_pixelBuffer = nil;
        _latestPixelBuffer = nil;
        _vid = -1;
        _state = 0;

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
    [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
              andArg1:end
              andArg2:_state
             andExtra:nil];
    if (_ijkMediaPlayer) {
        [_ijkMediaPlayer shutdown];
        _ijkMediaPlayer = nil;
    }
    if (_vid >= 0) {
        [_textureRegistry unregisterTexture:_vid];
        _vid = -1;
        _textureRegistry = nil;
    }

    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, nil, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old) {
        CVPixelBufferRelease(old);
    }

    /*
    if (_cachePixelBufer) {
        CVPixelBufferRelease(_cachePixelBufer);
        _cachePixelBufer = nil;
    }
     */
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

    CVPixelBufferRef newBuffer = CVPixelBufferRetain(pixelbuffer);

    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }

    if (old) {
        CVPixelBufferRelease(old);
    }
    /*
    if (_cachePixelBufer != nil)
        CVPixelBufferRelease(_cachePixelBufer);

    if (pixelbuffer != nil) {
        _cachePixelBufer = CVPixelBufferRetain(pixelbuffer);
        //_cachePixelBufer = pixelbuffer;
    }
    atomic_exchange(&_pixelBuffer, _cachePixelBufer);
    */
    if (_vid >= 0) {
        [_textureRegistry textureFrameAvailable:_vid];
    }
}

- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    /*
    CVPixelBufferRef pixelBuffer = atomic_exchange(&_pixelBuffer, nil);
    CVPixelBufferRef copyoutBuffer = NULL;
    if (pixelBuffer) {
        CVPixelBufferRetain(pixelBuffer);
        copyoutBuffer = pixelBuffer;
        while (!OSAtomicCompareAndSwapPtrBarrier(copyoutBuffer, pixelBuffer, (void **)&pixelBuffer)) {
            copyoutBuffer = pixelBuffer;
        }
    }
     */
    return pixelBuffer;
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

- (void)handleEvent:(int)what
            andArg1:(int)arg1
            andArg2:(int)arg2
           andExtra:(void *)extra {
    switch (what) {
    case IJKMPET_PREPARED:
        [_eventSink success:@{
            @"event" : @"prepared",
            @"duration" : @([_ijkMediaPlayer getDuration]),
        }];
        break;
    case IJKMPET_PLAYBACK_STATE_CHANGED:
        _state = arg1;
        [_eventSink success:@{
            @"event" : @"state_change",
            @"new" : @(arg1),
            @"old" : @(arg2),
        }];
        break;
    case IJKMPET_VIDEO_RENDERING_START:
    case IJKMPET_AUDIO_RENDERING_START:
        [_eventSink success:@{
            @"event" : @"rendering_start",
            @"type" : what == IJKMPET_VIDEO_RENDERING_START ? @"video"
                                                            : @"audio",
        }];
        break;
    case IJKMPET_BUFFERING_START:
    case IJKMPET_BUFFERING_END:
        [_eventSink success:@{
            @"event" : @"freeze",
            @"value" :
                [NSNumber numberWithBool:what == IJKMPET_BUFFERING_START],
        }];
        break;
    case IJKMPET_BUFFERING_UPDATE:
        [_eventSink success:@{
            @"event" : @"buffering",
            @"head" : @(arg1),
            @"percent" : @(arg2),
        }];
        break;
    case IJKMPET_VIDEO_SIZE_CHANGED:
        [_eventSink success:@{
            @"event" : @"size_changed",
            @"width" : @(arg1),
            @"height" : @(arg2),
        }];
        break;
    case IJKMPET_ERROR:
        [_eventSink error:[NSString stringWithFormat:@"%d", arg1]
                  message:extra ? [NSString stringWithUTF8String:extra] : nil
                  details:@(arg2)];
        break;
    default:
        break;
    }
}

- (void)onEvent4Player:(IJKFFMediaPlayer *)player
              withType:(int)what
               andArg1:(int)arg1
               andArg2:(int)arg2
              andExtra:(void *)extra {
    switch (what) {
    case IJKMPET_PREPARED:
    case IJKMPET_PLAYBACK_STATE_CHANGED:
    case IJKMPET_BUFFERING_START:
    case IJKMPET_BUFFERING_END:
    case IJKMPET_BUFFERING_UPDATE:
    case IJKMPET_VIDEO_SIZE_CHANGED:
    case IJKMPET_VIDEO_RENDERING_START:
    case IJKMPET_AUDIO_RENDERING_START:
    case IJKMPET_ERROR:
        [self handleEvent:what andArg1:arg1 andArg2:arg2 andExtra:extra];
        break;
    default:
        break;
    }
}

- (void)setOptions:(NSDictionary *)options {
    for (id cat in options) {
        NSDictionary *option = [options objectForKey:cat];
        for (NSString *key in option) {
            id optValue = [option objectForKey:key];
            if ([optValue isKindOfClass:[NSNumber class]]) {
                [_ijkMediaPlayer
                    setOptionIntValue:[optValue longLongValue]
                               forKey:key
                           ofCategory:(IJKFFOptionCategory)[cat intValue]];
            } else if ([optValue isKindOfClass:[NSString class]]) {
                [_ijkMediaPlayer
                    setOptionValue:optValue
                            forKey:key
                        ofCategory:(IJKFFOptionCategory)[cat intValue]];
            }
        }
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
    } else if ([@"applyOptions" isEqualToString:call.method]) {
        [self setOptions:argsMap];
        result(nil);
    } else if ([@"setDateSource" isEqualToString:call.method]) {
        NSString *url = argsMap[@"url"];
        NSURL *aUrl = [NSURL URLWithString: [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        bool file404 = false;
        if ([@"asset" isEqualToString:aUrl.scheme]) {
            NSString *host = aUrl.host;
            NSString *asset = [host length] == 0
                                  ? [_registrar lookupKeyForAsset:aUrl.path]
                                  : [_registrar lookupKeyForAsset:aUrl.path
                                                      fromPackage:host];
            if ([asset length] > 0) {
                NSString *path = [[NSBundle mainBundle] pathForResource:asset
                                                                 ofType:nil];
                if ([path length] > 0)
                    url = path;
            }
            if ([url isEqualToString:argsMap[@"url"]]) {
                file404 = true;
            }
        } else if ([@"file" isEqualToString:aUrl.scheme] ||
                   [aUrl.scheme length] == 0) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if (![fileManager fileExistsAtPath:aUrl.path]) {
                file404 = true;
            }
        }
        if (file404) {
            result([FlutterError errorWithCode:@"-875574348"
                                       message:[@"Local File not found:"
                                                   stringByAppendingString:url]
                                       details:nil]);
        } else {
            [_ijkMediaPlayer setDataSource:url];
            [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
                      andArg1:initialized
                      andArg2:-1
                     andExtra:nil];
            result(nil);
        }
    } else if ([@"prepareAsync" isEqualToString:call.method]) {
        [_ijkMediaPlayer prepareAsync];
        [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
                  andArg1:asyncPreparing
                  andArg2:-1
                 andExtra:nil];
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
        [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
                  andArg1:stopped
                  andArg2:-1
                 andExtra:nil];
        result(nil);
    } else if ([@"reset" isEqualToString:call.method]) {
        [_ijkMediaPlayer reset];
        [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
                  andArg1:idle
                  andArg2:-1
                 andExtra:nil];
        result(nil);
    } else if ([@"getCurrentPosition" isEqualToString:call.method]) {
        long pos = [_ijkMediaPlayer getCurrentPosition];
        result(@(pos));
    } else if ([@"setVolume" isEqualToString:call.method]) {
        double volume = [argsMap[@"volume"] doubleValue];
        [_ijkMediaPlayer setPlaybackVolume:(float)volume];
        result(nil);
    } else if ([@"seekTo" isEqualToString:call.method]) {
        long pos = [argsMap[@"msec"] longValue];
        [_ijkMediaPlayer seekTo:pos];
        if (_state == completed)
            [self handleEvent:IJKMPET_PLAYBACK_STATE_CHANGED
                      andArg1:paused
                      andArg2:-1
                     andExtra:nil];
        result(nil);
    } else if ([@"setLoop" isEqualToString:call.method]) {
        int loopCount = [argsMap[@"loop"] intValue];
        [_ijkMediaPlayer setLoop:loopCount];
    } else if ([@"setSpeed" isEqualToString:call.method]) {
        float speed = [argsMap[@"speed"] doubleValue];
        [_ijkMediaPlayer setSpeed:speed];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
