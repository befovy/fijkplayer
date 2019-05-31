#import "FijkPlugin.h"

@implementation FijkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"befovy.com/fijk"
            binaryMessenger:[registrar messenger]];
  FijkPlugin* instance = [[FijkPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
      NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    result([@"iOS " stringByAppendingString:osVersion]);
  } else if([@"init" isEqualToString:call.method]) {
      NSDictionary *args =  call.arguments;
      result(FlutterMethodNotImplemented);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
