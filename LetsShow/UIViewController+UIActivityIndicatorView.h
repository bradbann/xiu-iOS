//
//  UIViewController+UIActivityIndicatorView.h
//  SEGApp
//
//  Created by .... on 16/2/26.
//  Copyright © 2016年 chinda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (UIActivityIndicatorView)
-(void)startLoadingIndicatorWithTitle:(NSString *)labelText;
-(void)startLoadingIndicator;
-(void)endLoadingIndicator;

-(void)startLoadingIndicatorInUserInteractionDisabledWithTitle:(NSString *)labelText;
-(void)endLoadingIndicatorInUserInteractionEnabled;

-(void)changeHUDLabelText:(NSString *)labelText;
@end

