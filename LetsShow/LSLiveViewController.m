//
//  ViewController.m
//  LetsShow
//
//  Created by 吴建国&郑克明 on 15/10/15.
//  Copyright © 2015年 kankancity. All rights reserved.
//

#import "LSSimpleTools.h"
#import "LSLiveViewController.h"
#import "IMClient.h"
#import <WebKit/WebKit.h>
#import "LSScriptMsgHandle.h"
#import "LSPopWindowViewController.h"
#import "LSMainTabBarController.h"
#import "UIViewController+UIActivityIndicatorView.h"
#import "CCVideoPlayView.h"
#import "LSBaseNavigationViewController.h"
#import "LrdOutputView.h"
@interface LSLiveViewController () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, IMClientDelegate, CCVideoPlayViewDelegate, LrdOutputViewDelegate>
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic) IMClient *client;
@property (nonatomic,strong) LSScriptMsgHandle *scriptMsgHandle;
@property (nonatomic,strong) CCVideoPlayView *ccPlayView;
@end


@implementation LSLiveViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.scriptMsgHandle = [[LSScriptMsgHandle alloc] init];
    [self setupWebView];
    [self setupNotification];
    [self addAllScriptMsgHandle];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = self.nickName;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showMenu:)];
    
    self.view.backgroundColor = [LSSimpleTools stringTOColor:@"#F10D5F"];
    
    //禁止控制器当第一个视图是scroll视图时候自动插入contentOffset!!!!!!!!!!!!!!!!
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.alpha = 1;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

-(void)dealloc{
    NSLog(@"live controller dealloc");
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setupPlayerWithURL: (NSURL *)playerURL{
    //rtmp://192.168.0.245:1937/xiu/3
    //rtmp://live.hkstv.hk.lxdns.com/live/hks
//    NSString *liveUrlString = self.liveUrl.relativeString;
//    NSString *roomidString = [[liveUrlString pathComponents] objectAtIndex:2];
//    NSString *playUrlString = [NSString stringWithFormat:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
//    playerURL = [NSURL URLWithString:playUrlString];
    CGRect statusFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGRect frame = CGRectMake(0, statusFrame.size.height, self.view.frame.size.width, self.view.frame.size.width * 3.0 / 4.0);
    
    CCVideoPlayView *playView = [CCVideoPlayView videoPlayViewWithFrame:frame URL:playerURL delegate:self];
    playView.indicatorColor = [LSSimpleTools stringTOColor:@"#F10D5F"];
    playView.containerViewController = self;
    
    self.ccPlayView = playView;
    [self.view addSubview:self.ccPlayView];
}

- (void)setupNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationDidEnterBackground :(NSNotification *)notification{
    [self.ccPlayView stopPlay];
}

- (void)applicationWillEnterForeground :(NSNotification *)notification{
    [self.ccPlayView startPlay];
}

- (void)goBack{
    [self.ccPlayView stopPlay];
    [self.ccPlayView removeFromSuperview];
    self.ccPlayView = nil;
    [self removeAllScriptMsgHandle];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.client != nil) {
        [self.client close];
        self.client = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showMenu:(UIBarButtonItem *)btn{
    LrdCellModel *one = [[LrdCellModel alloc] initWithTitle:@"举报主播" imageName:@"report"];
    CGFloat y = 64;//[(UIView *)self.topLayoutGuide frame].size.height;
    LrdOutputView *menu = [[LrdOutputView alloc] initWithDataArray:@[one] origin:CGPointMake(self.view.bounds.size.width - 15, y) width:125 height:44 direction:kLrdOutputViewDirectionRight];
    menu.delegate = self;
    [menu pop];
}

-(void)didSelectedAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        UIAlertController *resultAlert = [UIAlertController alertControllerWithTitle:@"处理结果"
                                                                                     message:@"举报成功,我们将在24小时内处理!谢谢."
                                                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [resultAlert addAction:defaultAction];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"请选择举报类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* breakTheRuleAction = [UIAlertAction actionWithTitle:@"违法违规内容" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self presentViewController:resultAlert animated:YES completion:nil];
                                                              }];
        UIAlertAction* sexAction = [UIAlertAction actionWithTitle:@"低俗色情内容" style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action) {
                                                                  [self presentViewController:resultAlert animated:YES completion:nil];
                                                              }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
        
        [alert addAction:breakTheRuleAction];
        [alert addAction:sexAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
//
//- (void)showMenuActionSheet {
//    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:@"url" message:nil preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *loadNew = [UIAlertAction actionWithTitle:@"加载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        NSString *text = actionController.textFields[0].text;
//        if (text != nil) {
//            NSURL *url = [[NSURL alloc] initWithString:text];
//            if (url != nil) {
//                [self.webView loadRequest:[NSURLRequest requestWithURL: url]];
//                [[NSUserDefaults standardUserDefaults] setURL:url forKey:@"oldUrl"];
//            }
//        }
//    }];
//    UIAlertAction *reloadAction = [UIAlertAction actionWithTitle:@"刷新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////        [self.webView reload];
//        [self.webView reloadFromOrigin];
//    }];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        
//    }];
//    [actionController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
//        textField.text = self.webView.URL.absoluteString;
////        [textField resignFirstResponder];
//    }];
//    [actionController addAction:loadNew];
//    [actionController addAction:reloadAction];
//    [actionController addAction:cancelAction];
//    [self presentViewController:actionController animated:YES completion:nil];
//}

#pragma mark - CCViewPlayer代理

-(void)CCPlayerOnToolViewHide{
    //降低导航栏透明度
    [UIView animateWithDuration:0.5 animations:^{
        self.navigationController.navigationBar.alpha = 0.01;
    } completion:nil];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(void)CCPlayerOnToolViewShow{
    //增加导航栏透明度
    [UIView animateWithDuration:0.5 animations:^{
        self.navigationController.navigationBar.alpha = 1;
    } completion:nil];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)CCPlayerOnTapPlayView:(id)sender{
    NSString *exec = @"onClickVideo();";
    [self.webView evaluateJavaScript:exec completionHandler:nil];
}

#pragma mark - Web操作

-(void)addAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller addScriptMessageHandler:self name:@"ListenerOnClick"];
    [controller addScriptMessageHandler:self name:@"LocalShowPlayeronBack"];
    [controller addScriptMessageHandler:self name:@"LocalShowPlayerHeight"];
    [controller addScriptMessageHandler:self name:@"LoadPlayer"];
    [controller addScriptMessageHandler:self name:@"connect"];
    [controller addScriptMessageHandler:self name:@"sendMsg"];
    [controller addScriptMessageHandler:self name:@"close"];
    
    [controller addScriptMessageHandler:self name:@"NSLog"];
    
    CGFloat height;
    if (self.ccPlayView != nil){
        height = self.ccPlayView.frame.size.height - self.navigationController.navigationBar.frame.size.height;
    }else{
        height = self.view.frame.size.width * 3 / 4 - self.navigationController.navigationBar.frame.size.height;
    }
    
    NSString *scriptString = [NSString stringWithFormat:@"window.localShowPlayerHeight = %f",height];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:scriptString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [controller addUserScript:userScript];
}
-(void)removeAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller removeScriptMessageHandlerForName:@"ListenerOnClick"];
    [controller removeScriptMessageHandlerForName:@"LocalShowPlayeronBack"];
    [controller removeScriptMessageHandlerForName:@"LocalShowPlayerHeight"];
    [controller removeScriptMessageHandlerForName:@"LoadPlayer"];
    [controller removeScriptMessageHandlerForName:@"connect"];
    [controller removeScriptMessageHandlerForName:@"sendMsg"];
    [controller removeScriptMessageHandlerForName:@"close"];
    
    [controller removeScriptMessageHandlerForName:@"NSLog"];
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    configuration.userContentController = controller;
    configuration.processPool = [LSMainTabBarController sharedWKWebPool];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];

    [self.webView loadRequest:[NSURLRequest requestWithURL:self.liveUrl]];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
//    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    __weak typeof(self) weakSelf = self;
    self.scriptMsgHandle.loginOpenBlock = ^(NSURL *url){
        typeof(self) strongSelf = weakSelf;
        LSPopWindowViewController *popWinVC = [[LSPopWindowViewController alloc] init];
        LSBaseNavigationViewController *navController = [[LSBaseNavigationViewController alloc] initWithRootViewController:popWinVC];
        popWinVC.openUrl = url;
        popWinVC.title = @"登录";
        popWinVC.dismissBlock = ^{
            NSLog(@"log in success,page reload");
            [strongSelf.webView reload];
        };
        [strongSelf presentViewController:navController animated:YES completion:nil];
    };
    self.scriptMsgHandle.liveBackBlock = ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf goBack];
    };
    self.scriptMsgHandle.liveLoadPlayerBlock = ^(NSURL *playerURL){
        typeof(self) strongSelf = weakSelf;
        if (strongSelf.ccPlayView != nil) {
            return;
        }
        [strongSelf setupPlayerWithURL:playerURL];
    };
    
    self.scriptMsgHandle.nsLogBlock = ^(NSString *log){
        NSLog(@"Web log:%@",log);
    };
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
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


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%@, %@", message.name, message.body);
    if ([message.name isEqual: @"connect"]) {
        
        if (self.client != nil) {
            [self.client close];
        }
        NSDictionary *body = (NSDictionary *)message.body;
        NSString *host = [body objectForKey:@"host"];
        NSNumber *port = [body objectForKey:@"port"];
        self.client = [[IMClient alloc] init];
        self.client.delegate = self;
        [self.client connectToHost:host withPort:(int)port.integerValue];
    } else if ([message.name isEqual:@"sendMsg"]) {
//        NSLog(@"发送sendMsg请求 %@",message.body);
        if (self.client != nil) {
            NSDictionary *body = (NSDictionary *)message.body;
            NSNumber *target = [body objectForKey:@"target"];
            NSString *msg = [body objectForKey:@"msg"];
            [self.client sendToTarget:target.longLongValue withMsg:msg];
        }
    } else if ([message.name isEqual:@"close"]) {
        if (self.client != nil) {
            [self.client close];
            self.client = nil;
        }
    }
    
    [self.scriptMsgHandle handleScriptMessage:message];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self performSelectorOnMainThread:@selector(endLoadingIndicator) withObject:nil waitUntilDone:NO];
}
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [self performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
}

- (void)onConnected {
    NSLog(@"onConnected");
    NSString *exec = @"onConnected();";
    [self.webView evaluateJavaScript:exec completionHandler:nil];
}

- (void)onError {
    NSLog(@"onError");
    NSString *exec = @"onError();";
    [self.webView evaluateJavaScript:exec completionHandler:nil];
    [self.client close];
    self.client = nil;
}

- (void)onMessageFromSrc:(unsigned long long)src withMsg:(NSString *)message {
    if (message) {
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if (!error) {
            if ([[jsonObject objectForKey:@"id"] intValue] == 17 || [[jsonObject objectForKey:@"id"] intValue] == 18) {
                
            }else{
                //NSLog(@"onMessageFromSrc:%llu,withMsg:%@", src, message);
            }
        }
    }
    NSString *exec = [NSString stringWithFormat:@"onMessageFromSrc(%llu, %@);", src, message];
    [self.webView evaluateJavaScript:exec completionHandler:nil];
}

@end
