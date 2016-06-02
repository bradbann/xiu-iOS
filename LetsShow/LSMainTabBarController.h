//
//  MainTabBarController.h
//  LetsShow
//
//  Created by 郑克明 on 16/2/25.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface LSMainTabBarController : UITabBarController

+(WKProcessPool *) sharedWKWebPool;

@end
