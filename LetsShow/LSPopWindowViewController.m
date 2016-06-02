//
//  LSPopWindowViewController.m
//  LetsShow
//
//  Created by 郑克明 on 16/2/25.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "LSSimpleTools.h"
#import "LSPopWindowViewController.h"
#import <WebKit/WebKit.h>
#import "LSScriptMsgHandle.h"
#import "LSMainTabBarController.h"
#import "UIViewController+UIActivityIndicatorView.h"
#import "CCOpenService.h"
#import "LSInAppPurchaseHelper.h"
#import "LSProductItem.h"
@import StoreKit;

@interface LSPopWindowViewController () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic,strong) LSScriptMsgHandle *scriptMsgHandle;
@property (nonatomic,strong) LSInAppPurchaseHelper *helper;
@property (nonatomic,strong) NSArray *products;
@end

@implementation LSPopWindowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scriptMsgHandle = [[LSScriptMsgHandle alloc] init];
    [self setupWebView];
    [self addAllScriptMsgHandle];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
    self.navigationItem.rightBarButtonItem = item;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [LSSimpleTools stringTOColor:@"#F10D5F"];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)dealloc{
    NSLog(@"pop controller dealloc");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)dismiss:(id)sender{
    [self removeAllScriptMsgHandle];
    self.webView = nil;
    self.scriptMsgHandle = nil;
    self.helper = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - In-App Purchase
//get product list
-(void)loadProductsList{
    self.helper = [LSInAppPurchaseHelper sharedHelper];
    [self.helper requestProductList:^(NSArray *products) {
        NSLog(@"products %@",products);
        if (products.count == 0) {
            NSLog(@"products ia empty~~");
            return;
        }
        self.products = products;
        [self displayProducts];
    }];
}

-(void)displayProducts{
    //Directory to json
    NSMutableDictionary *jsonDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *productsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.products.count; i++) {
        SKProduct *p = self.products[i];
        [jsonDic setObject:p.price forKey:@"price"];
        [jsonDic setObject:@( floorf(p.price.doubleValue * 0.686) * 100 ) forKey:@"coin"];
        [jsonDic setObject:@(i) forKey:@"no"];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:nil];
        [productsArray addObject:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    }
    NSLog(@"%@",productsArray);
    NSMutableString *productsString = [[NSMutableString alloc] initWithString:@"["];
    for (int i = 0; i< productsArray.count; i++) {
        [productsString appendFormat:@"%@,",productsArray[i]];
    }
    [productsString deleteCharactersInRange:NSMakeRange(productsString.length - 1, 1)];
    [productsString appendString:@"]"];
    NSString *exec = [NSString stringWithFormat:@"onInAppPurchaseDisplayUI(%@);",productsString];
    [self.webView evaluateJavaScript:exec completionHandler:^(id d, NSError *error) {
        NSLog(@"%@%@",d,error);
        [self performSelectorOnMainThread:@selector(endLoadingIndicatorInUserInteractionEnabled) withObject:nil waitUntilDone:NO];
    }];
}


#pragma mark - Web操作

-(void)addAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller addScriptMessageHandler:self name:@"AuthOnLoginSuccess"];
    [controller addScriptMessageHandler:self name:@"UserSettingOnSetupSuccess"];
    [controller addScriptMessageHandler:self name:@"AuthWeixinAuth"];
    [controller addScriptMessageHandler:self name:@"AuthQQAuth"];
    [controller addScriptMessageHandler:self name:@"AuthSinaAuth"];
    [controller addScriptMessageHandler:self name:@"InAppPurchaseSelectWithNo"];
}
-(void)removeAllScriptMsgHandle{
    WKUserContentController *controller = self.webView.configuration.userContentController;
    [controller removeScriptMessageHandlerForName:@"AuthOnLoginSuccess"];
    [controller removeScriptMessageHandlerForName:@"UserSettingOnSetupSuccess"];
    [controller removeScriptMessageHandlerForName:@"AuthWeixinAuth"];
    [controller removeScriptMessageHandlerForName:@"AuthQQAuth"];
    [controller removeScriptMessageHandlerForName:@"AuthSinaAuth"];
    [controller removeScriptMessageHandlerForName:@"InAppPurchaseSelectWithNo"];
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    configuration.userContentController = controller;
    configuration.processPool = [LSMainTabBarController sharedWKWebPool];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    if (!self.openUrl) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSURL alloc] initWithString:@"http://www.17xiu.com/m/user"]]];
    }else{
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.openUrl]];
    }
    
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.bounces = YES;
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    //设置进入直播间block
    __weak typeof(self) weakSelf = self;
    
    self.scriptMsgHandle.loginSuccessBlock = ^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.dismissBlock();
        [strongSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    };
    self.scriptMsgHandle.setupSuccessBlock = ^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.dismissBlock();
        [strongSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    
    //Charge
    self.scriptMsgHandle.inAppPurchaseSelectWithNo = ^(NSDictionary *selectedData){
        typeof(self) strongSelf = weakSelf;
        NSString *no = selectedData[@"no"];
        NSString *userID = selectedData[@"uid"];
        NSString *orderNum = selectedData[@"orderNum"];
        
        NSDictionary *buyData = @{@"uid":userID, @"product":strongSelf.products[[no intValue]], @"orderNum":orderNum};
        [strongSelf startLoadingIndicatorInUserInteractionDisabledWithTitle:@"支付中"];
        [strongSelf.helper requestingPaymentWithProduct:buyData quantity:1 respondHander:^(NSDictionary *result) {
            if (result == nil) {
                [strongSelf endLoadingIndicatorInUserInteractionEnabled];
            }else if( [result[@"status"] intValue] == 2) {
                NSLog(@"取消购买~ ~ ~");
                [strongSelf endLoadingIndicatorInUserInteractionEnabled];
            }
            else if( [result[@"status"] intValue] == 1) {
                [strongSelf changeHUDLabelText:@"等待服务器确认"];
            }else if( [result[@"status"] intValue] == 0){
                NSLog(@"服务器已经确认订单,购买成功");
                if (strongSelf.dismissBlock) {
                    [strongSelf.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        strongSelf.dismissBlock();
                    }];
                }
                [strongSelf endLoadingIndicatorInUserInteractionEnabled];
            }else if( [result[@"status"] intValue] == 0){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                               message:@"亲,网络不稳定,程序会在重启后自动重试."
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {}];
                [alert addAction:defaultAction];
                [strongSelf presentViewController:alert animated:YES completion:nil];
                [strongSelf endLoadingIndicatorInUserInteractionEnabled];
            }
        }];
    };
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
}


-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [self.scriptMsgHandle handleScriptMessage:message];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    if (self.type == PopWindowTypeCharge) {
        [self loadProductsList];
    }else{
        [self performSelectorOnMainThread:@selector(endLoadingIndicator) withObject:nil waitUntilDone:NO];
    }
}
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    if (self.type == PopWindowTypeCharge) {
        [self performSelectorOnMainThread:@selector(startLoadingIndicatorWithTitle:) withObject:@"加载商品" waitUntilDone:NO];
    }else{
        [self performSelectorOnMainThread:@selector(startLoadingIndicator) withObject:nil waitUntilDone:NO];
    }
}

@end
