//
//  IMClient.h
//  PipObjectC
//
//  Created by 吴建国 on 15/9/25.
//  Copyright © 2015年 wujianguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IMClientDelegate <NSObject>
- (void)onConnected;
- (void)onError;
- (void)onMessageFromSrc:(unsigned long long)src withMsg:(NSString *)message;
@end

@interface IMClient : NSObject
@property(nonatomic, weak) id<IMClientDelegate> delegate;
- (void)connectToHost:(NSString *)host withPort:(int)port;
- (void)close;
- (void)sendToTarget:(unsigned long long)target withMsg:(NSString *)message;
@end
