//
//  LSUserViewController.m
//  LetsShow
//
//  Created by 郑克明 on 16/2/24.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "AppDelegate.h"
#import "LSUserViewController.h"
#import <WebKit/WebKit.h>
#import "LSScriptMsgHandle.h"
#import "LSLiveViewController.h"
#import "LSMainTabBarController.h"
#import "LSPopWindowViewController.h"
#import "UIViewController+UIActivityIndicatorView.h"
#import "MJRefresh.h"
#import "CCOpenService.h"
#import "LSUserAgreementViewController.h"
#import "LSInAppPurchaseHelper.h"
@import StoreKit;

@interface LSUserViewController () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic,strong) LSScriptMsgHandle *scriptMsgHandle;
@end

@implementation LSUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scriptMsgHandle = [[LSScriptMsgHandle alloc] init];
    [self setupWebView];
    
    //增加下拉刷新
    [self addRefreshHeader];
    
    self.isRequireReloadWebView = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if (!self.webView.isLoading && self.isRequireReloadWebView) {
        [self.webView reload];
    }else{
        self.isRequireReloadWebView = YES;
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
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
#pragma mark - 其他视图
- (void)addRefreshHeader{
    MJRefreshNormalHeader *mjHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        // 进入刷新状态后会自动调用这个block
        [self.webView reload];
    }];
    self.webView.scrollView.mj_header = mjHeader;
}
#pragma mark - Web操作

-(void)addAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller addScriptMessageHandler:self name:@"ListenerOnClick"];
    [controller addScriptMessageHandler:self name:@"AuthOnLoginSuccess"];
    [controller addScriptMessageHandler:self name:@"AuthWeixinAuth"];
    [controller addScriptMessageHandler:self name:@"AuthQQAuth"];
    [controller addScriptMessageHandler:self name:@"AuthSinaAuth"];
    [controller addScriptMessageHandler:self name:@"SendUserInfo"];
}
-(void)removeAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller removeScriptMessageHandlerForName:@"ListenerOnClick"];
    [controller removeScriptMessageHandlerForName:@"AuthOnLoginSuccess"];
    [controller removeScriptMessageHandlerForName:@"AuthWeixinAuth"];
    [controller removeScriptMessageHandlerForName:@"AuthQQAuth"];
    [controller removeScriptMessageHandlerForName:@"AuthSinaAuth"];
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    
    configuration.userContentController = controller;
    configuration.processPool = [LSMainTabBarController sharedWKWebPool];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:@"http://www.17xiu.com/m/user"]]];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    //设置进入直播间block
    __weak typeof(self) weakSelf = self;
    self.scriptMsgHandle.liveOpenBlock = ^(NSURL *url, NSString *name){
        typeof(self) strongSelf = weakSelf;
        LSLiveViewController *lvc = [[LSLiveViewController alloc] init];
        lvc.liveUrl = url;
        lvc.nickName = name;
        [strongSelf.navigationController pushViewController:lvc animated:YES];
    };
    self.scriptMsgHandle.logoutBlock = ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf.webView loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:@"http://www.17xiu.com/m/user"]]];
    };
    
    self.scriptMsgHandle.loginSuccessBlock = ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf.webView loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:@"http://www.17xiu.com/m/user"]]];
    };
    
    self.scriptMsgHandle.usersetOpenBlock = ^(NSURL *url){
        typeof(self) strongSelf = weakSelf;
        //弹出设置窗后,当前webview默认不自动刷新
        strongSelf.isRequireReloadWebView = NO;
        
        LSPopWindowViewController *popWinVC = [[LSPopWindowViewController alloc] init];
        popWinVC.type = PopWindowTypeUserSet;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:popWinVC];
        popWinVC.openUrl = url;
        popWinVC.title = @"设置";
        popWinVC.dismissBlock = ^{
            [strongSelf.webView reload];
        };
        [strongSelf presentViewController:navController animated:YES completion:nil];
        
    };
    
    //Charge for In-App Purchase
    self.scriptMsgHandle.chargeOpenBlock = ^(NSURL *url){
        typeof(self) strongSelf = weakSelf;
        if (![SKPaymentQueue canMakePayments]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                                 message:@"您的设备不支持APP内购功能,请开启后重试."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [strongSelf presentViewController:alert animated:YES completion:nil];
            return;
        }
        if ([[LSInAppPurchaseHelper sharedHelper] hasUnverifyOrder]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                           message:@"您有已支付但未成功验证的订单,请重启APP后再试."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [strongSelf presentViewController:alert animated:YES completion:nil];
            return;
        }
        //弹出设置窗后,当前webview默认不自动刷新
        strongSelf.isRequireReloadWebView = NO;
        
        LSPopWindowViewController *popWinVC = [[LSPopWindowViewController alloc] init];
        popWinVC.type = PopWindowTypeCharge;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:popWinVC];
        popWinVC.openUrl = url;
        popWinVC.title = @"充值";
        popWinVC.dismissBlock = ^{
            [strongSelf.webView reload];
        };
        [strongSelf presentViewController:navController animated:YES completion:nil];
        
    };
    
    //微信登录
    self.scriptMsgHandle.authWeixinAuth = ^{
        typeof(self) strongSelf = weakSelf;
        CCOpenService *wxService = [CCOpenService getOpenServiceWithName:CCOpenServiceNameWeiXin];
        [wxService requestOpenAccount:^(CCOpenRespondEntity *respond) {
            if (respond == nil) {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"^_^亲,您木有安装微信哟~ " delegate:nil cancelButtonTitle:@"知道啦" otherButtonTitles:nil];
                [alert show];
                return;
            }
            NSLog(@"respond is %@",respond);
            NSDictionary *userInfo = respond.data;
            NSString *string = [NSString stringWithFormat:@"%@",userInfo];
            NSLog(@"%@",string);
            NSString *exec = [NSString stringWithFormat:@"onAuthSuccess('17xiu_m_third_login', 'wechat', '%@', '%@', '%@', '%@', '%@');", userInfo[@"unionid"], userInfo[@"openid"], userInfo[@"nickname"], userInfo[@"headimgurl"], userInfo[@"sex"]];
            [strongSelf.webView evaluateJavaScript:exec completionHandler:nil];
            [strongSelf performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
        }];
    };
    
    //QQ登录
    self.scriptMsgHandle.authQQAuth = ^{
        typeof(self) strongSelf = weakSelf;
        CCOpenService *qqService = [CCOpenService getOpenServiceWithName:CCOpenServiceNameQQ];
        [qqService requestOpenAccount:^(CCOpenRespondEntity *respond) {
            NSLog(@"respond is %@",respond.data);
            NSDictionary *userInfo = respond.data;
            
            NSString *gender;
            if ([(NSString *)userInfo[@"gender"] isEqualToString: @"男"]) {
                gender = @"0";
            }else{
                gender = @"1";
            }
            
            NSString *exec = [NSString stringWithFormat:@"onAuthSuccess('17xiu_m_third_login', 'qq', '%@', '%@', '%@', '%@', '%@');", userInfo[@"unionid"], userInfo[@"openid"], userInfo[@"nickname"], userInfo[@"figureurl_qq_2"], gender];
            [strongSelf.webView evaluateJavaScript:exec completionHandler:nil];
            [strongSelf performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
        }];
    };
    
    //微博登录
    self.scriptMsgHandle.authSinaAuth = ^{
        typeof(self) strongSelf = weakSelf;
        CCOpenService *wbService = [CCOpenService getOpenServiceWithName:CCOpenServiceNameWeiBo];
        [wbService requestOpenAccount:^(CCOpenRespondEntity *respond) {
            NSLog(@"respond is %@",respond.data);
            NSDictionary *userInfo = respond.data;
            
            NSString *gender;
            if ([(NSString *)userInfo[@"gender"] isEqualToString: @"m"]) {
                gender = @"0";
            }else{
                gender = @"1";
            }
            
            NSString *exec = [NSString stringWithFormat:@"onAuthSuccess('17xiu_m_third_login', 'weibo', '%@', '%@', '%@', '%@', '%@');", userInfo[@"unionid"], userInfo[@"userID"], userInfo[@"name"], userInfo[@"avatarLargeUrl"], gender];
            [strongSelf.webView evaluateJavaScript:exec completionHandler:nil];
            [strongSelf performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
        }];
    };
    
    //User agreement window
    self.scriptMsgHandle.userAgreementBlock = ^{
        typeof(self) strongSelf = weakSelf;
        LSUserAgreementViewController *userAgreementVC = [[LSUserAgreementViewController alloc] initWithNibName:nil bundle:nil];
        userAgreementVC.hidesBottomBarWhenPushed = YES;
        [strongSelf.navigationController pushViewController:userAgreementVC animated:YES];
    };
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addAllScriptMsgHandle];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [actionController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:actionController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [actionController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [actionController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [self presentViewController:actionController animated:YES completion:nil];
}


-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [self.scriptMsgHandle handleScriptMessage:message];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self performSelectorOnMainThread:@selector(endLoadingIndicator) withObject:nil waitUntilDone:NO];
    [self.webView.scrollView.mj_header endRefreshing];
}
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [self performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
}

@end
