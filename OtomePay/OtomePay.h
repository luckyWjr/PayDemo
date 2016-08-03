//
//  OtomePay.h
//  OtomePay
//
//  Created by wjr on 16/7/21.
//  Copyright © 2016年 wjr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, ErrorType){
    ErrorNoNet,//无网络
    ErrorPayUnabel,//内购被禁用
    ErrorPayIdError,//无效的支付id
    ErrorNoProject,//产品列表为空
    ErrorPayFail,//支付失败
};

@interface OtomePay : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>

+(OtomePay *)sharedInstance;

#pragma mark - 获取产品列表
-(void)initProductData;
- (void)payWithPayId:(NSString*)payId;

- (void)addObserver;
- (void)removeObserver;

#pragma mark - 获取产品列表成功失败的block
@property(nonatomic, copy) void(^getProductSuc)(NSMutableString* msg);
@property(nonatomic, copy) void(^getProductFail)(ErrorType type);

#pragma mark - 购买成功失败的block
@property(nonatomic, copy) void(^paySuc)(NSString* order);
@property(nonatomic, copy) void(^payFail)(ErrorType type);

@end
