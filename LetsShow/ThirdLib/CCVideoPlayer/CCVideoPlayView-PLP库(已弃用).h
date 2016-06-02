//
//  CCVideoPlayView.h
//  LetsShow
//
//  Created by 郑克明 on 16/3/1.
//  Copyright © 2016年 kankancity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLPlayerKit/PLPlayer.h>

@protocol CCVideoPlayViewDelegate <NSObject>
@optional
/**
 *  触摸播放器
 *
 *  @param sender 触发的手势对象
 */
-(void)CCPlayerOnTapPlayView:(_Nullable id)sender;
/**
 *  开始播放
 */
-(void)CCPlayerOnPlay;
/**
 *  播放暂停
 */
-(void)CCPlayerOnPause;
/**
 *  播放停止
 */
-(void)CCPlayerOnStop;
/**
 *  切换成横屏模式
 */
-(void)CCPlayerOnSwitchFullModel;
/**
 *  切换成竖屏模式
 */
-(void)CCPlayerOnSwitchPortraitModel;
/**
 *  工具栏显示
 */
-(void)CCPlayerOnToolViewShow;
/**
 *  工具栏隐藏
 */
-(void)CCPlayerOnToolViewHide;

/// 后台任务启动及关闭的回调
- (void)playerWillBeginBackgroundTask:(nonnull PLPlayer *)player;
- (void)player:(nonnull PLPlayer *)player willEndBackgroundTask:(BOOL)isExpirationOccured;

/// status 变更回调
- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state;
- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error;
@end


//工具栏显示时长(超时后自动隐藏)
extern NSInteger const CCPlayerShowToolTimeInterval;

@interface CCVideoPlayView : UIView

@property (nonatomic,strong,nonnull) NSURL *url;
//用于显示全屏的控制器
@property (nonatomic,weak) UIViewController *containerViewController;
//代理
@property (nonatomic,weak) id<CCVideoPlayViewDelegate> delegate;
/**
 *  从xib文件中创建视图
 *
 *  @return CCVideoPlayView
 */
+ (instancetype _Nonnull)videoPlayViewWithURL:(nonnull NSURL *)url delegate:(_Nullable id <CCVideoPlayViewDelegate>)delegate;

/**
 *  停止播放
 */
- (void)stopPlay;
/**
 *  开始播放
 */
- (void)startPlay;
@end
