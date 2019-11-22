//
//  FijkHostOption.h
//  fijkplayer
//
//  Created by Bai Shuai on 2019/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FijkHostOption : NSObject

- (void)setIntValue:(NSNumber *)value forKey:(NSString *)key;

- (void)setStrValue:(NSString *)value forKey:(NSString *)key;

- (NSNumber *)getIntValue:(NSString *)kay defalt:(NSNumber *)defalt;

- (NSString *)getStrValue:(NSString *)key defalt:(NSString *)defalt;

@end

NS_ASSUME_NONNULL_END
