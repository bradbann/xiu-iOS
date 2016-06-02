//
//  LSInAppPurchaseHelper.m
//  LetsShow
//
//  Created by 郑克明 on 16/4/22.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import "AFNetworking.h"
#import "LSInAppPurchaseHelper.h"
#import <CommonCrypto/CommonCrypto.h>


@interface LSInAppPurchaseHelper ()
@property (nonatomic,copy) void (^respondHander)(NSArray *);
@property (nonatomic, copy) void (^paymentRespondHander)(NSDictionary *);
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic,strong) NSDictionary *buyData;
@property (nonatomic) BOOL isVerifing;

@end

//static SKProductsRequest *productsRequest;

@implementation LSInAppPurchaseHelper

+(instancetype)sharedHelper{
    static LSInAppPurchaseHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        helper = [[LSInAppPurchaseHelper alloc] initPrivate];
    });
    return helper;
}

-(instancetype) initPrivate{
    return [super init];
    
}

//提醒用户要使用 单例初始化
-(instancetype) init{
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use +[LSInAppPurchaseHelper sharedHelper]" userInfo:nil];
}

- (void)dealloc{
    NSLog(@"LSInAppPurchaseHelper dealloc~");
}

-(NSArray *)productIdentifiers{
    if (!_productIdentifiers) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"product_ids"
                                             withExtension:@"plist"];
        NSArray *productIdentifiers = [NSArray arrayWithContentsOfURL:url];
        _productIdentifiers = productIdentifiers;
    }
    return _productIdentifiers;
}

-(BOOL)requestProductList:(void(^)(NSArray *products))respondHander {
    self.respondHander = respondHander;
    if (!SKPaymentQueue.canMakePayments) {
        return NO;
    }
    [self validateProductIdentifiers:self.productIdentifiers];
    return YES;
}


- (void)validateProductIdentifiers:(NSArray *)productIdentifiers{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    // Keep a strong reference to the request.
    self.request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

// Custom method to calculate the SHA-256 hash using Common Crypto
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
    const int HASH_SIZE = 32;
    unsigned char hashedChars[HASH_SIZE];
    const char *accountName = [userAccountName UTF8String];
    size_t accountNameLen = strlen(accountName);
    
    // Confirm that the length of the user name is small enough
    // to be recast when calling the hash function.
    if (accountNameLen > UINT32_MAX) {
        NSLog(@"Account name too long to hash: %@", userAccountName);
        return nil;
    }
    CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
    
    // Convert the array of bytes into a string showing its hex representation.
    NSMutableString *userAccountHash = [[NSMutableString alloc] init];
    for (int i = 0; i < HASH_SIZE; i++) {
        // Add a dash every four bytes, for readability.
        if (i != 0 && i%4 == 0) {
            [userAccountHash appendString:@"-"];
        }
        [userAccountHash appendFormat:@"%02x", hashedChars[i]];
    }
    
    return userAccountHash;
}

- (void)verifyReceipt:(SKPaymentTransaction *)transaction withResultHandler:(void(^)(NSDictionary *result))resultHander{
    if (self.isVerifing) {
        return;
    }
    self.isVerifing = YES;
    NSData *purchasedData;
    NSLog(@"购买成功,正在联系服务器验证receipt %@",[[NSBundle mainBundle] appStoreReceiptURL]);
    purchasedData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (!purchasedData) {
        NSLog(@"无法获取票据~");
        resultHander(nil);
        return;
    }
    
    //Requst 17 server...
    //如果是程序启动时,系统调用到此,说明是上次购买没完成,需要特殊处理,即事先保存每一次购买的数据到本地的plist,然后在重试时候buyData需要从本地plist中加载出来
    NSMutableArray *data;
    NSMutableArray *removeDataIndex = [[NSMutableArray alloc] init];
    BOOL isRetry = NO;
    if (!self.buyData) {
        data = [self loadBuyData];
        isRetry = YES;
    }else{
        NSString *receiptString = [purchasedData base64EncodedStringWithOptions:0];
        NSDictionary *dic = @{@"receipt-data": receiptString, @"orderNum":self.buyData[@"orderNum"]};
        data = [[NSMutableArray alloc] initWithObjects:dic, nil];
    }
    
    for (int i = 0; i< data.count; i++) {
        NSLog(@"开始请求17服务器");
        NSDictionary *parameters = data[i];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager POST:@"http://www.17xiu.com/m/iosreceipt" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"responseObject:%@",responseObject);
            if ([responseObject[@"status"] intValue] != -1) {
                // successful
                if (isRetry) {
                    [removeDataIndex addObject:@(i)];
                    if (i == data.count - 1) {
                        NSMutableArray *localData = [self loadBuyData];
                        for (int j = 0; j < removeDataIndex.count; j++) {
                            int index = [removeDataIndex[j] intValue];
                            [localData removeObjectAtIndex:index];
                        }
                        [self saveBuyData:localData];
                    }
                }
            }else if ([responseObject[@"status"] intValue] == -1){
                if (!isRetry) {
                    NSMutableArray *localData = [self loadBuyData];
                    [localData addObject:parameters];
                    [self saveBuyData:localData];
                }
            }
            
            resultHander(responseObject);
            if (i == data.count - 1) {
                self.isVerifing = NO;
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            resultHander(nil);
            if (!isRetry) {
                NSMutableArray *localData = [self loadBuyData];
                [localData addObject:parameters];
                [self saveBuyData:localData];
            }
            if (i == data.count - 1) {
                self.isVerifing = NO;
            }
        }];
    }
}

- (NSString *)pathForPurchasedPlist{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    return [documentDirectory stringByAppendingPathComponent:@"purchased.plist"];
}

//save buy data to array in plist when verify server fails
- (void)saveBuyData:(NSArray *)data{
    [data writeToFile:[self pathForPurchasedPlist] atomically:YES];
}

- (NSMutableArray *)loadBuyData{
    NSMutableArray *data = [[NSMutableArray alloc] initWithContentsOfFile:[self pathForPurchasedPlist]];
    if (data == nil) {
        data = [[NSMutableArray alloc] init];
        [self saveBuyData:data];
    }
    return data;
}

#pragma mark - <SKProductsRequestDelegate>
// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response{
    if (self.respondHander) {
        self.respondHander(response.products);
    }
}

-(BOOL)requestingPaymentWithProduct:(NSDictionary *)buyData quantity:(NSInteger)quantity respondHander:(void(^)(NSDictionary *result))respondHander{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:buyData[@"product"]];
    self.paymentRespondHander = respondHander;
    payment.quantity = quantity;
    payment.applicationUsername = [self hashedValueForAccountName:[NSString stringWithFormat:@"%@",buyData[@"uid"]]];
    self.buyData = buyData;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return YES;
}

#pragma mark - <SKPaymentTransactionObserver>
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            // Call the appropriate custom method for the transaction state.
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"购买进行中");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"购买延迟");
                break;
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"购买失败");
                if (self.paymentRespondHander) {
                    NSDictionary *dic = @{@"status":@(2)};
                    self.paymentRespondHander(dic);
                }
                break;
            }
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"SKPaymentTransactionStatePurchased");
                //test
                //[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                if (self.paymentRespondHander) {
                    NSDictionary *dic = @{@"status":@(1)};
                    self.paymentRespondHander(dic);
                }
                [self verifyReceipt:transaction withResultHandler:^(NSDictionary *result) {
                    if (result == nil) {
                        NSLog(@"Request 17 server fail..Retry on later");
                        if (self.paymentRespondHander) {
                            self.paymentRespondHander(nil);
                        }
                        return;
                    }else{
                        if (self.paymentRespondHander) {
                            self.paymentRespondHander(result);
                        }
                    }
                    if ([result[@"status"] intValue] != -1) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                }];
                break;
            }
            default:
                // For debugging
                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads{
    NSLog(@"%@",downloads);
}

-(BOOL)hasUnverifyOrder {
    return [[self loadBuyData] count] > 0;
}
@end
