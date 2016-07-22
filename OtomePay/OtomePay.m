//
//  OtomePay.m
//  OtomePay
//
//  Created by wjr on 16/7/21.
//  Copyright © 2016年 wjr. All rights reserved.
//

#import "OtomePay.h"
#import "Reachability.h"

#define PAY_ITEM1 @"item1"
#define PAY_ITEM3 @"item3"
#define PAY_ITEM4 @"item4"
#define PAY_ITEM5 @"item5"
#define PAY_ITEM6 @"item6"
#define PAY_ITEM7 @"item7"
#define PAY_ITEM8 @"item8"

static OtomePay *sharedObj = nil;

@interface OtomePay (){
    SKProduct *currentProduct;
}

@property (nonatomic, copy) NSArray *productsArr;
@property (nonatomic, assign) NSInteger clientCurrencyType;
@property (nonatomic, copy) NSDictionary *currencyTypes;
@property (nonatomic, strong) NSSet *productsIdentifierSet;
@property (nonatomic, strong) Reachability *reach;

@end

@implementation OtomePay

+(OtomePay *)sharedInstance {
    @synchronized(self) {
        if (sharedObj == nil) {
            sharedObj = [[self alloc] init];
        }
    }
    
    return sharedObj;
}

-(id)init {
    @synchronized(self) {
        if (!(self = [super init])) {
            return nil;
        }
        
        self.productsArr = [[NSArray alloc]init];
        self.currencyTypes=@{@"Unknown":@0,
                             @"USD":@1,
                             @"CAD":@2,
                             @"MXN":@3,
                             @"AUD":@4,
                             @"NZD":@5,
                             @"JPY":@6,
                             @"CNY":@7,
                             @"SGD":@8,
                             @"HKD":@9,
                             @"TWD":@10,
                             @"IDR":@11,
                             @"INR":@12,
                             @"RUB":@13,
                             @"TRY":@14,
                             @"ILS":@15,
                             @"ZAR":@16,
                             @"SAR":@17,
                             @"AED":@18,
                             @"GBP":@19,
                             @"DKK":@20,
                             @"SEK":@21,
                             @"CHF":@22,
                             @"NOK":@23,
                             @"Euro":@24,
                             @"EUR":@25,
                             @"Max":@32};
        self.productsIdentifierSet = [NSSet setWithObjects:
                                      PAY_ITEM1,
                                      PAY_ITEM3,
                                      PAY_ITEM4,
                                      PAY_ITEM5,
                                      PAY_ITEM6,
                                      PAY_ITEM7,
                                      PAY_ITEM8,
                                      nil];
        self.reach = [Reachability reachabilityForInternetConnection];
        
        return  self;
    }
}


#pragma mark -SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if ([response.products count] == 0) {
        self.getProductFail(@"请求产品数据为空！");
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
    
    //self.productsArr//
    NSArray *products = [[NSArray alloc] initWithArray:[response.products sortedArrayUsingComparator:^NSComparisonResult(SKProduct *obj1, SKProduct *obj2) {
        if ([[numberFormatter stringFromNumber:obj1.price] intValue] > [[numberFormatter stringFromNumber:obj2.price] intValue]) {
            return NSOrderedDescending;
        }
        else if([[numberFormatter stringFromNumber:obj1.price] intValue] < [[numberFormatter stringFromNumber:obj2.price] intValue]) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }]];
    
    
    NSString *newCurrencyTypeS=nil;
    
    if (products != nil && products.count > 0) {
        
        newCurrencyTypeS = [[((SKProduct *)[products objectAtIndex:0]).priceLocale.localeIdentifier componentsSeparatedByString:@"="] objectAtIndex:1];
        
        if (nil == [self.currencyTypes valueForKey:newCurrencyTypeS]) {
            self.clientCurrencyType = 0;
        }
        else {
            self.clientCurrencyType = [[self.currencyTypes valueForKey:newCurrencyTypeS] intValue];
        }
        
        NSLog(@"clientCurrencyType %@", @(self.clientCurrencyType));
    }
    
    self.productsArr = products;
    
    if (self.productsArr == nil || self.productsArr.count == 0) {
        self.getProductFail(@"获取的产品列表为空");
    }
    else{
        NSMutableString* msg = [[NSMutableString alloc]init];
        for(SKProduct *product in self.productsArr){
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [formatter setLocale:product.priceLocale];
            NSString *product_price = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:product.price]];
            product_price = [product_price stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSLog(@"wjr-price-%@", product_price);
            
            NSString* eachMsg = [NSString stringWithFormat:@"%@|%@|%@|%@\t", product.productIdentifier, product_price, product.localizedDescription, product.localizedTitle];
            
            [msg appendString:eachMsg];
        }
        self.getProductSuc(msg);
    }    
}

-(void)initProductData {
    [self getSKProductsWithIdentifier:self.productsIdentifierSet];
}

-(void)getSKProductsWithIdentifier:(NSSet *)identifierSet {
    if ([self.reach currentReachabilityStatus] == NotReachable) {
        self.getProductFail(@"No internet connection");
    }
    else {
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:
                                      identifierSet];
        request.delegate = self;
        [request start];
    }
}

#pragma mark - SKPaymentTransactionObserver Methods
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                // Item was successfully purchased!
//                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                // Return transaction data. App should provide user with purchased product.
//                [self restoreTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                // Purchase was either cancelled by user or an error occurred.
//                [self failedTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

@end
