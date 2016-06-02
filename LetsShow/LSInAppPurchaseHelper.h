//
//  LSInAppPurchaseHelper.h
//  LetsShow
//
//  Created by 郑克明 on 16/4/22.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import <Foundation/Foundation.h>
@import StoreKit;

@class SKProduct;

@interface LSInAppPurchaseHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic,strong) NSArray *productIdentifiers;

+(instancetype)sharedHelper;

-(BOOL)requestProductList:(void(^)(NSArray *products))respondHander;

-(BOOL)requestingPaymentWithProduct:(NSDictionary *)buyData quantity:(NSInteger)quantity respondHander:(void(^)(NSDictionary *result))respondHander;

-(BOOL)hasUnverifyOrder;
@end
