//
//  LSScriptMsgHandle.h
//  LetsShow
//
//  H5页面跳转类型type
//  0: 登录页	http://www.17xiu.com/m/login
//  1: 直播页	http://www.17xiu.com/2/m
//  2: 用户设置页	http://www.17xiu.com/m/userset
//  3: 充值页	http://www.17xiu.com/m/charge

//  Created by 郑克明 on 16/2/24.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface LSScriptMsgHandle : NSObject
@property (nonatomic, copy) void (^loginSuccessBlock)(void);
/**
 *  操作设置成功
 */
@property (nonatomic, copy) void (^setupSuccessBlock)(void);
@property (nonatomic, copy) void (^logoutBlock)(void);
@property (nonatomic, copy) void (^liveBackBlock)(void);
@property (nonatomic, copy) void (^liveLoadPlayerBlock)(NSURL *url);
//打开新窗口
@property (nonatomic, copy) void (^loginOpenBlock)(NSURL *url);
@property (nonatomic, copy) void (^liveOpenBlock)(NSURL *url, NSString *name);
@property (nonatomic, copy) void (^usersetOpenBlock)(NSURL *url);
@property (nonatomic, copy) void (^chargeOpenBlock)(NSURL *url);

@property (nonatomic, copy) void (^nsLogBlock)(NSString *log);

@property (nonatomic,copy) void (^authWeixinAuth)(void);
@property (nonatomic,copy) void (^authQQAuth)(void);
@property (nonatomic,copy) void (^authSinaAuth)(void);

@property (nonatomic,copy) void (^userAgreementBlock)(void);

@property (nonatomic,copy) void (^inAppPurchaseSelectWithNo)(NSDictionary *selectedData);

- (void)handleScriptMessage:(WKScriptMessage *)msg;
@end
