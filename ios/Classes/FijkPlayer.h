//
//  FijkPlayer.h
//  fijkplayer
//
//  Created by Befovy on 2019/6/21.
//

#import <FIJKPlayer/IJKFFMediaPlayer.h>
#import <FIJKPlayer/IJKSDLGLViewProtocol.h>
#import <Foundation/Foundation.h>

#import <Flutter/FlutterPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface FijkPlayer : NSObject <FlutterStreamHandler, IJKMPEventHandler,
                                  FlutterTexture, IJKCVPBViewProtocol>

@property(atomic, readonly) NSNumber *playerId;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
