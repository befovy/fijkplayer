
#import "FijkPlugin.h"
#import "FijkPlayer.h"

#import <FIJKPlayer/IJKFFMoviePlayerController.h>
#import <Flutter/Flutter.h>

@implementation FijkPlugin {
    NSObject<FlutterPluginRegistrar> *_registrar;
    NSMutableDictionary<NSNumber *, FijkPlayer *> *_fijkPlayers;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel =
        [FlutterMethodChannel methodChannelWithName:@"befovy.com/fijk"
                                    binaryMessenger:[registrar messenger]];
    FijkPlugin *instance = [[FijkPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];

    FijkPlayer *player = [[FijkPlayer alloc] initWithRegistrar:registrar];
    int64_t vid = [[registrar textures] registerTexture:player];
    [player shutdown];
    [[registrar textures] unregisterTexture:vid];
}

- (instancetype)initWithRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _fijkPlayers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {

    NSDictionary *argsMap = call.arguments;
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];
        result([@"iOS " stringByAppendingString:osVersion]);
    } else if ([@"init" isEqualToString:call.method]) {
        NSLog(@"FLUTTER: %s %@", "call init:", argsMap);
        result(NULL);
    } else if ([@"createPlayer" isEqualToString:call.method]) {
        FijkPlayer *fijkplayer =
            [[FijkPlayer alloc] initWithRegistrar:_registrar];
        NSNumber *playerId = fijkplayer.playerId;
        _fijkPlayers[playerId] = fijkplayer;
        result(playerId);
    } else if ([@"releasePlayer" isEqualToString:call.method]) {
        NSNumber *pid = argsMap[@"pid"];
        FijkPlayer *fijkPlayer = [_fijkPlayers objectForKey:pid];
        [fijkPlayer shutdown];
        if (fijkPlayer != nil) {
            [_fijkPlayers removeObjectForKey:pid];
        }
        result(nil);
    } else if ([@"logLevel" isEqualToString:call.method]) {
        NSNumber *level = argsMap[@"level"];
        int l = [level intValue] / 100;
        l = l < 0 ? 0 : l;
        l = l > 8 ? 8 : l;
        [IJKFFMoviePlayerController setLogLevel:l];
        result(nil);
    } else if ([@"setOrientationPortrait" isEqualToString:call.method]) {
        UIInterfaceOrientationMask mask = [[UIApplication sharedApplication]
            supportedInterfaceOrientationsForWindow:nil];
        UIDeviceOrientation deviceOrientation =
            [UIDevice currentDevice].orientation;
        if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown &&
            (mask & UIInterfaceOrientationMaskPortraitUpsideDown))
            [[UIDevice currentDevice]
                setValue:@(UIInterfaceOrientationPortraitUpsideDown)
                  forKey:@"orientation"];
        else if (mask & UIInterfaceOrientationMaskPortrait)
            [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait)
                                        forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        result(nil);
    } else if ([@"setOrientationLandscape" isEqualToString:call.method]) {
        UIInterfaceOrientationMask mask = [[UIApplication sharedApplication]
            supportedInterfaceOrientationsForWindow:nil];

        UIDeviceOrientation deviceOrientation =
            [UIDevice currentDevice].orientation;
        if (deviceOrientation == UIDeviceOrientationLandscapeLeft &&
            (mask & UIInterfaceOrientationMaskLandscapeLeft))
            [[UIDevice currentDevice]
                setValue:@(UIInterfaceOrientationLandscapeLeft)
                  forKey:@"orientation"];
        else if (mask & UIInterfaceOrientationMaskLandscapeRight)
            [[UIDevice currentDevice]
                setValue:@(UIInterfaceOrientationLandscapeRight)
                  forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        result(nil);
    } else if ([@"setOrientationAuto" isEqualToString:call.method]) {
        UIInterfaceOrientationMask mask = [[UIApplication sharedApplication]
            supportedInterfaceOrientationsForWindow:nil];

        if (mask & UIInterfaceOrientationMaskPortrait)
            [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait)
                                        forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
