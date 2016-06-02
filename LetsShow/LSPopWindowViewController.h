//
//  LSPopWindowViewController.h
//  LetsShow
//  处理弹出登录,弹出充值页面
//  Created by 郑克明 on 16/2/25.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PopWindowType) {
    PopWindowTypeUserSet = 0,
    PopWindowTypeLogin,
    PopWindowTypeCharge
};

@interface LSPopWindowViewController : UIViewController
@property (nonatomic) PopWindowType type;
@property (nonatomic,strong) NSURL *openUrl;
@property (nonatomic,copy) void (^dismissBlock)(void);
@end
