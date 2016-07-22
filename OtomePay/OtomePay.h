//
//  OtomePay.h
//  OtomePay
//
//  Created by wjr on 16/7/21.
//  Copyright © 2016年 wjr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface OtomePay : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>

+(OtomePay *)sharedInstance;

#pragma mark - 获取产品列表
-(void)initProductData;

#pragma mark - 获取产品列表成功失败的block
@property(nonatomic, copy) void(^getProductSuc)(NSMutableString* msg);
@property(nonatomic, copy) void(^getProductFail)(NSString* msg);

@end
