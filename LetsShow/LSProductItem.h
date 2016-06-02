//
//  LSProductItem.h
//  LetsShow
//
//  Created by 郑克明 on 16/4/28.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSProductItem : NSObject

@property (nonatomic) NSInteger no;
@property (nonatomic, strong) NSDecimalNumber* price;
@property (nonatomic) NSInteger coin;

@end
