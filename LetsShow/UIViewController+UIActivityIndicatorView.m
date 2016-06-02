//
//  UIViewController+UIActivityIndicatorView.m
//  SEGApp
//
//  Created by .... on 16/2/26.
//  Copyright © 2016年 chinda. All rights reserved.
//

#import "UIViewController+UIActivityIndicatorView.h"
#import <MBProgressHUD/MBProgressHUD.h>
@implementation UIViewController (UIActivityIndicatorView)

-(void)startLoadingIndicator{
    [self startLoadingIndicatorWithTitle:nil];
}

-(void)startLoadingIndicatorWithTitle: (NSString *)labelText
{
/*  if ([self.view viewWithTag:9577]) {
        return;
    }
    UIActivityIndicatorView *activityIndicator= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = self.view.center;//CGPointMake(self.view.bounds.size.width/2,self.view.bounds.size.height/2);
    [activityIndicator setColor:[UIColor darkGrayColor]];
    activityIndicator.tag=9577;
    [self.view addSubview:activityIndicator];
//    [[[UIApplication sharedApplication].delegate window]setUserInteractionEnabled:NO];
    [activityIndicator startAnimating];
*/
    if ([self.view viewWithTag:9577]) {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.tag = 9577;
//    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.labelText = labelText;
    
}
-(void)endLoadingIndicator
{
//    UIActivityIndicatorView *activityIndicator=[self.view viewWithTag:9577];
//    [activityIndicator stopAnimating];
//    [activityIndicator removeFromSuperview];
    MBProgressHUD *hud=[self.view viewWithTag:9577];
    [hud hide:YES];
}

-(void)startLoadingIndicatorInUserInteractionDisabledWithTitle:(NSString *)labelText{
    [[[UIApplication sharedApplication].delegate window]setUserInteractionEnabled:NO];
    [self startLoadingIndicatorWithTitle:labelText];
    
}

-(void)endLoadingIndicatorInUserInteractionEnabled{
    [[[UIApplication sharedApplication].delegate window]setUserInteractionEnabled:YES];
    [self endLoadingIndicator];
}

-(void)changeHUDLabelText:(NSString *)labelText {
	MBProgressHUD *hud=[self.view viewWithTag:9577];
    hud.labelText = labelText;
}

@end
