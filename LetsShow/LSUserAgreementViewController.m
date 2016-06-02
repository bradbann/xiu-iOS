//
//  LSUserAgreementViewController.m
//  LetsShow
//
//  Created by 郑克明 on 16/4/26.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import "LSUserAgreementViewController.h"

@interface LSUserAgreementViewController ()
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property(nonatomic, strong) NSTextStorage *textStorage;
@end

@implementation LSUserAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.title = @"17秀用户协议";
    //If diy the back button,here must set it's delegate
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self loadContextText];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

-(void)loadContextText{
    self.textStorage = [[NSTextStorage alloc] init];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"user-agreement" withExtension:@"txt"];
    NSString *string = [NSString stringWithContentsOfURL:url encoding: NSUTF8StringEncoding error:nil];
    [self.textStorage addLayoutManager:self.contentTextView.layoutManager];
    [self.textStorage replaceCharactersInRange:NSMakeRange(0,0) withString:string];
}
-(void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
