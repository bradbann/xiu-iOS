//
//  LSDiscoveryViewController.m
//  LetsShow
//
//  Created by 郑克明 on 16/2/23.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "LSDiscoveryViewController.h"
#import <WebKit/WebKit.h>
#import "LSScriptMsgHandle.h"
#import "LSLiveViewController.h"
#import "LSMainTabBarController.h"
#import "UIViewController+UIActivityIndicatorView.h"
#import "MJRefresh.h"

@interface LSDiscoveryViewController () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic,strong) LSScriptMsgHandle *scriptMsgHandle;
@end

@implementation LSDiscoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scriptMsgHandle = [[LSScriptMsgHandle alloc] init];
    [self setupWebView];
    //增加下拉刷新
    [self addRefreshHeader];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
//    if (!self.webView.isLoading) {
//        [self.webView reload];
//    }
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
}
-(void)removeAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller removeScriptMessageHandlerForName:@"ListenerOnClick"];
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    configuration.userContentController = controller;
    configuration.processPool = [LSMainTabBarController sharedWKWebPool];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:@"http://www.17xiu.com/m/discovery"]]];
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
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addAllScriptMsgHandle];
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"%@, %@", message.name, message.body);
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
