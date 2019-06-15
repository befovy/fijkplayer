
#import "FijkPlugin.h"

#import <Flutter/Flutter.h>

@implementation FijkPlugin {
    NSObject<FlutterPluginRegistrar> * _registrar;
    NSObject<FlutterTextureRegistry> * _textures;
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
        _textures = [registrar textures];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
      NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    result([@"iOS " stringByAppendingString:osVersion]);
  } else if([@"init" isEqualToString:call.method]) {
      FlutterTexture
      _textures registerTexture:<#(nonnull NSObject<FlutterTexture> *)#>
      
      NSDictionary *args =  call.arguments;
      result(FlutterMethodNotImplemented);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
