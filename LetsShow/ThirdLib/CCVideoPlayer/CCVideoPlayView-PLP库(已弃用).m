//
//  CCVideoPlayView.m
//  LetsShow
//
//  Created by 郑克明 on 16/3/1.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import "CCVideoPlayView.h"
#import "CCFullViewController.h"

NSInteger const CCPlayerShowToolTimeInterval = 3;
static NSString *status[] = {
    @"PLPlayerStatusUnknow",
    @"PLPlayerStatusPreparing",
    @"PLPlayerStatusReady",
    @"PLPlayerStatusCaching",
    @"PLPlayerStatusPlaying",
    @"PLPlayerStatusPaused",
    @"PLPlayerStatusStopped",
    @"PLPlayerStatusError"
};
@interface CCVideoPlayView() <PLPlayerDelegate>
//用户展示视频,默认展示播放器背景图
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchOrientation;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

//播放器驱动
@property (nonatomic,strong) PLPlayer *player;
//工具栏定时器
@property (nonatomic,strong) NSTimer *toolViewTimer;
//工具栏动画是否正在执行
@property (nonatomic) BOOL isToolViewShowAnimating;

//全屏控制器(暂无)
@property (nonatomic,weak) CCFullViewController *fullVC;
//CCVideoPlayView最初被指定的原始位置
@property (nonatomic) CGRect originalViewFrame;
@property (nonatomic) BOOL isFullModel;
@end

@implementation CCVideoPlayView

+ (instancetype)videoPlayViewWithURL:(NSURL *)url delegate:(id<CCVideoPlayViewDelegate>)delegate{
    PLPlayerOption *option = [PLPlayerOption defaultOption];
    CCVideoPlayView *view = (CCVideoPlayView *)[[[NSBundle mainBundle] loadNibNamed:@"CCVideoPlayView" owner:nil options:nil] firstObject];
    if (view) {
        view.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        view.url = url;
        view.player = [PLPlayer playerWithURL:view.url option:option];
        view.player.delegate = view;
        view.delegate = delegate;
        [view playOrPause:nil];
    }
    return view;
}

-(instancetype)init{
    @throw [NSException exceptionWithName:@"Not supported init" reason:@"Use +[CCVideoPlayView videoPlayView]" userInfo:nil];
}

-(void)awakeFromNib{
    [super awakeFromNib];
//    [self.volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"MinimumTrackImage"] forState:UIControlStateNormal];
//    [self.volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"MaximumTrackImage"] forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"thumbImage"] forState:UIControlStateNormal];
    
    //添加所有手势操作
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapRecognizer];
}

-(void)dealloc{
    NSLog(@"ccview dealloc~");
    if (self.player.isPlaying) {
        [self.player stop];
    }
    self.player = nil;
}
#pragma mark - 布局调试
- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView *subView in self.subviews) {
        if ([subView hasAmbiguousLayout]) {
            NSLog(@"AMBIGUOUS: %@", subView);
        }
    }
    if (!self.isFullModel) {
        self.imageView.frame = self.bounds;
        self.player.playerView.frame = self.imageView.frame;
    }
}

#pragma mark - 播放器工具栏操作
/**
 *  播放与暂停播放
 *
 *  @param sender 播放(暂停)按钮
 */
- (IBAction)playOrPause:(UIButton *)sender {
    //按钮未选中:准备播放.如果是播放,则开启定时器,定时隐藏工具栏,更改按钮为暂停图标
    //按钮被选中:准备暂停.如果是暂停,则显示工具栏,移除定时器,更改按钮为播放图标
    if (!sender) {
        //首次播放,系统自动触发点击事件,sender为nil
        UIView *playerView = self.player.playerView;
        [self.imageView addSubview:playerView];
        [self.player play];
        self.playOrPauseBtn.selected = YES;
    }else if (sender.selected) {
        [self.player stop];
    }else{
        [self.player play];
    }
    sender.selected = !sender.selected;
}
/**
 *  全屏切换
 *  由CCVideoPlayView父视图所在的控制器负责显示全屏
 *  @param sender 全屏切换按钮
 */
- (IBAction)switchOrientation:(UIButton *)sender {
    if (sender.selected) {
        //切换正常
        [self.fullVC dismissViewControllerAnimated:NO completion:^{
            [self.containerViewController.view addSubview:self];
            //视频驱动层的大小和imageView一样大,而imageView自适应self.frame
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.frame = self.originalViewFrame;
                self.player.playerView.frame = self.imageView.frame;
            } completion:^(BOOL finished){
                if (finished) {
                    self.isFullModel = NO;
                }
            }];
        }];
        sender.selected = NO;
        if ([self.delegate respondsToSelector:@selector(CCPlayerOnSwitchPortraitModel)]) {
            [self.delegate CCPlayerOnSwitchPortraitModel];
        }
    }else{
        //切换全屏
        CCFullViewController *fullVC = [[CCFullViewController alloc] init];
        self.originalViewFrame = self.frame;
        [self.containerViewController presentViewController:fullVC animated:NO completion:^{
            //注意此时高<宽,所以视频高等于屏幕高,视频宽为视频高的3/4
            [fullVC.view addSubview:self];
            self.player.playerView.frame = CGRectMake(0, 0, fullVC.view.frame.size.height * 4 / 3, fullVC.view.frame.size.height);
            self.center = fullVC.view.center;
            self.player.playerView.center = self.center;
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.frame = fullVC.view.bounds;
            } completion:nil];
        }];
        self.fullVC = fullVC;
        sender.selected = YES;
        if ([self.delegate respondsToSelector:@selector(CCPlayerOnSwitchFullModel)]) {
            [self.delegate CCPlayerOnSwitchFullModel];
        }
        self.isFullModel = YES;
    }
    
    [self removeToolViewTimer];
    [self addToolViewTimer];
}

/**
 *  切换工具视图显示或隐藏
 *
 *  @param isShowView 显示或者隐藏视图
 */
- (void)setToolViewShowState:(BOOL)isShowView{
    if (isShowView) {
        [self removeToolViewTimer];
        [self showToolView];
        //重新添加定时器
        [self addToolViewTimer];
    }else{
        [self removeToolViewTimer];
        if (self.player.status != PLPlayerStatusStopped) {
            [self hideToolView];
        }
    }
}

/**
 *  隐藏工具栏
 */
- (void)hideToolView{
    self.isToolViewShowAnimating = YES;
    [UIView animateWithDuration:1 animations:^{
        self.toolView.alpha = 0;
    } completion:^(BOOL finished){
        if (finished) {
            self.isToolViewShowAnimating = NO;
        }
    }];
    
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnToolViewHide)]) {
        [self.delegate CCPlayerOnToolViewHide];
    }
}

/**
 *  显示工具栏
 */
- (void)showToolView{
    [UIView animateWithDuration:1 animations:^{
        self.toolView.alpha = 1;
    } completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnToolViewShow)]) {
        [self.delegate CCPlayerOnToolViewShow];
    }
}

#pragma  mark - 定时器操作
/**
 *  定时隐藏工具栏
 */
- (void)addToolViewTimer{
//    self.toolViewTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow:CCPlayerShowToolTimeInterval] interval:0 target:self selector:@selector(hideToolView) userInfo:nil repeats:NO];
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:self.toolViewTimer forMode:NSDefaultRunLoopMode];
    NSLog(@"addToolViewTimer");
}

/**
 *  移除工具栏隐藏定时器
 */
- (void)removeToolViewTimer{
    //移除定时器
//    [self.toolViewTimer invalidate];
//    self.toolViewTimer = nil;
    NSLog(@"removeToolViewTimer");
}


/**
 *  某些操作需要定时器重新计时
 */
- (void)updateToolViewTimer{
    
}

#pragma mark - 手势操作
-(void)singleTap:(id)sender{
    if (self.toolView.alpha > 0.001) {
        [self setToolViewShowState:NO];
    }else if(!self.isToolViewShowAnimating){
        [self setToolViewShowState:YES];
    }
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnTapPlayView:)]) {
        [self.delegate CCPlayerOnTapPlayView:sender];
    }
}

#pragma mark - 实现PLPayer协议
/// 后台任务启动及关闭的回调
- (void)playerWillBeginBackgroundTask:(PLPlayer *)player{
    if ([self.delegate respondsToSelector:@selector(playerWillBeginBackgroundTask:)]) {
        [self.delegate playerWillBeginBackgroundTask:(PLPlayer *)player];
    }
}
- (void)player:(PLPlayer *)player willEndBackgroundTask:(BOOL)isExpirationOccured{
    if ([self.delegate respondsToSelector:@selector(player:willEndBackgroundTask:)]) {
        [self.delegate player:(PLPlayer *)player willEndBackgroundTask:(BOOL)isExpirationOccured];
    }
}

/// status 变更回调
- (void)player:(PLPlayer *)player statusDidChange:(PLPlayerStatus)state{
    NSLog(@"State: %@", status[state]);
    if (PLPlayerStatusPlaying == state) {
        [self addToolViewTimer];
    }
    if (PLPlayerStatusStopped == state) {
        [self removeToolViewTimer];
        [self showToolView];
    }
    if ([self.delegate respondsToSelector:@selector(player:statusDidChange:)]) {
        [self.delegate player:(PLPlayer *)player statusDidChange:(PLPlayerStatus)state];
    }
}
- (void)player:(PLPlayer *)player stoppedWithError:(NSError *)error{
    NSLog(@"State: Error %@", error);
    if ([self.delegate respondsToSelector:@selector(player:stoppedWithError:)]) {
        [self.delegate player:(PLPlayer *)player stoppedWithError:(NSError *)error];
    }
}

#pragma mark - 其他相关操作

- (void)stopPlay {
    [self playOrPause:self.playOrPauseBtn];
}

- (void)startPlay {
	[self playOrPause:self.playOrPauseBtn];
}

@end

