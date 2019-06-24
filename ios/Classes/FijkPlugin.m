
#import "FijkPlugin.h"
#import "FijkPlayer.h"

#import <Flutter/Flutter.h>


@implementation FijkPlugin {
    NSObject<FlutterPluginRegistrar> * _registrar;
    NSMutableDictionary<NSNumber *, FijkPlayer *> *_fijkPlayers;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"befovy.com/fijk"
            binaryMessenger:[registrar messenger]];
    
  FijkPlugin* instance = [[FijkPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    self = [super init];
    
    if (self) {
        _registrar = registrar;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    NSDictionary *argsMap = call.arguments;
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
      NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    result([@"iOS " stringByAppendingString:osVersion]);
  } else if([@"init" isEqualToString:call.method]) {
      NSLog(@"FLUTTER: %s %@", "call init:", argsMap);
      result(NULL);
  } else if([@"createPlayer" isEqualToString:call.method]) {
      FijkPlayer *fijkplayer = [[FijkPlayer alloc] initWithRegistrar:_registrar];
      NSNumber * playerId = fijkplayer.playerId;
      _fijkPlayers[playerId] = fijkplayer;
      result(playerId);
  } else if([@"releasePlayer" isEqualToString:call.method]){
      // int pid = call
        NSNumber *pid = argsMap[@"pid"];
        FijkPlayer *fijkPlayer = _fijkPlayers[pid];
        if (fijkPlayer != nil) {
            //[fijkPlayer start];
            [_fijkPlayers removeObjectForKey:pid];

        }
    } else {
      result(FlutterMethodNotImplemented);
  }
}

@end
