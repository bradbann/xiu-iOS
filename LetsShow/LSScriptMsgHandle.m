//
//  LSScriptMsgHandle.m
//  LetsShow
//
//  Created by 郑克明 on 16/2/24.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "LSScriptMsgHandle.h"

@implementation LSScriptMsgHandle


- (void)handleScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = (NSDictionary *)message.body;
    if ([message.name  isEqual: @"ListenerOnClick"]) {
        NSNumber *type = [body objectForKey:@"type"];
        NSURL *url;
        if ([[body allKeys] containsObject:@"url"]) {
            url = [[NSURL alloc] initWithString:[body objectForKey:@"url"]];
        }
        switch ([type integerValue]) {
            case 0:
                if (self.loginOpenBlock) {
                    self.loginOpenBlock(url);
                }
                break;
            case 1:
                if (self.liveOpenBlock) {
                    self.liveOpenBlock(url,[body objectForKey:@"nickname"]);
                }
                break;
            case 2:
                if (self.usersetOpenBlock) {
                    self.usersetOpenBlock(url);
                }
                break;
            case 3:
                if (self.chargeOpenBlock) {
                    self.chargeOpenBlock(url);
                }
                break;
            case 4:
                NSLog(@"Log out~~");
                if (self.logoutBlock) {
                    self.logoutBlock();
                }
                break;
            case 5:
                if (self.userAgreementBlock) {
                    self.userAgreementBlock();
                }
                break;
            default:
                break;
        }
    }else if ([message.name isEqualToString:@"AuthOnLoginSuccess"]){
        if (self.loginSuccessBlock) {
            self.loginSuccessBlock();
        }
    }else if ([message.name isEqualToString:@"UserSettingOnSetupSuccess"]){
        if (self.setupSuccessBlock) {
            self.setupSuccessBlock();
        }
    }else if ([message.name isEqualToString:@"LocalShowPlayeronBack"]){
        if (self.liveBackBlock) {
            self.liveBackBlock();
        }
    }else if ([message.name isEqualToString:@"LoadPlayer"]){
        if (self.liveLoadPlayerBlock) {
            NSURL *palyerUrl = [[NSURL alloc] initWithString:[body objectForKey:@"url"]];
            self.liveLoadPlayerBlock(palyerUrl);
        }
    }else if ([message.name isEqualToString:@"NSLog"]){
        if (self.nsLogBlock) {
            self.nsLogBlock([body objectForKey:@"log"]);
        }
    }else if ([message.name isEqualToString:@"AuthWeixinAuth"]){
        if (self.authWeixinAuth) {
            self.authWeixinAuth();
        }
    }else if ([message.name isEqualToString:@"AuthQQAuth"]){
        if (self.authQQAuth) {
            self.authQQAuth();
        }
    }else if ([message.name isEqualToString:@"AuthSinaAuth"]){
        if (self.authSinaAuth) {
            self.authSinaAuth();
        }
    }else if ([message.name isEqualToString:@"InAppPurchaseSelectWithNo"]){
        if (self.inAppPurchaseSelectWithNo) {
            self.inAppPurchaseSelectWithNo(body);
        }
    }
}
@end



