//
//  MainTabBarController.m
//  LetsShow
//
//  Created by 郑克明 on 16/2/25.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "LSMainTabBarController.h"

@interface LSMainTabBarController ()

@end

@implementation LSMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置所有tab选中图标
    NSArray *items = [[self tabBar] items];
    UITabBarItem *hotItem = items[0];
    UITabBarItem *discoveryItem = items[1];
    UITabBarItem *myItem = items[2];
    hotItem.selectedImage = [[UIImage imageNamed:@"HotSelc"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    discoveryItem.selectedImage = [[UIImage imageNamed:@"DiscoverySelc"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    myItem.selectedImage = [[UIImage imageNamed:@"MySelc"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+(WKProcessPool *) sharedWKWebPool {
    static WKProcessPool *sharedWebPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedWebPool = [[WKProcessPool alloc] init];
    });
    return sharedWebPool;
}

@end
