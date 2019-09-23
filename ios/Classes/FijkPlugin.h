#import <Flutter/Flutter.h>

@interface FijkPlugin : NSObject <FlutterPlugin, FlutterStreamHandler>

@property int playingCnt;
@property int playableCnt;

+ (FijkPlugin *)singleInstance;

@end
