//
//  OtomePay.m
//  OtomePay
//
//  Created by wjr on 16/7/21.
//  Copyright © 2016年 wjr. All rights reserved.
//

#import "OtomePay.h"
#import "Reachability.h"

#define PAY_ITEM1 @"com.ddianle.otome.item2"
#define PAY_ITEM3 @"com.ddianle.otome.item3"
#define PAY_ITEM4 @"com.ddianle.otome.item4"
#define PAY_ITEM5 @"com.ddianle.otome.item5"
#define PAY_ITEM6 @"com.ddianle.otome.item6"
#define PAY_ITEM7 @"com.ddianle.otome.item7"
#define PAY_ITEM8 @"com.ddianle.otome.item8"

static OtomePay *sharedObj = nil;

@interface OtomePay (){
    SKProduct *currentProduct;
}

@property (nonatomic, copy) NSArray *productsArr;
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
        self.getProductFail(ErrorNoProject);
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
    
//    NSString* type = [[((SKProduct *)[products objectAtIndex:0]).priceLocale.localeIdentifier componentsSeparatedByString:@"="] objectAtIndex:1];
    
    self.productsArr = products;
    
    if (self.productsArr == nil || self.productsArr.count == 0) {
        self.getProductFail(ErrorNoProject);
    }
    else{
        NSMutableString* msg = [[NSMutableString alloc]init];
        for(SKProduct *product in self.productsArr){
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [formatter setLocale:product.priceLocale];
            NSString *product_price = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:product.price]];
            product_price = [product_price stringByReplacingOccurrencesOfString:@" " withString:@""];
            
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
        self.getProductFail(ErrorNoNet);
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
        NSLog(@"wjr---transaction----%@", transaction.transactionIdentifier);
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            {
                // Item was successfully purchased!
                [self completeTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored://已经购买过该商品
                // Return transaction data. App should provide user with purchased product.
                [self restoreTransaction:transaction];
                
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
                break;
                
            case SKPaymentTransactionStateFailed:
            {
                // Purchase was either cancelled by user or an error occurred.
                [self failedTransaction:transaction];
                break;
            }
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSString *storeTransaction = [transaction.transactionReceipt base64Encoding];
    NSLog(@"wjr---paysuc---%@", storeTransaction);
    self.paySuc(storeTransaction);
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    NSArray* transactions = [SKPaymentQueue defaultQueue].transactions;
    if (transactions.count > 0) {
        //检测是否有未完成的交易
        SKPaymentTransaction* transaction = [transactions firstObject];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            [self completeTransaction:transaction];
        }
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled) {
        // Optionally, display an error here.
    }
    NSLog(@"wjr---payfail");
    self.payFail(ErrorPayFail);
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)payWithPayId:(NSString*)payId{
    if ([SKPaymentQueue canMakePayments]) {
        if ([self.reach currentReachabilityStatus] != NotReachable) {
            for(SKProduct *project in self.productsArr){
                if([payId isEqualToString:project.productIdentifier]){
//                    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                    NSLog(@"wjr-----payid-----%@", project.productIdentifier);
                    SKPayment *payment = [SKPayment paymentWithProduct:project];
                    [[SKPaymentQueue defaultQueue] addPayment:payment];
                    return;
                }
            }
            self.payFail(ErrorPayIdError);
        }
        else {
            //网络连接失败
            self.payFail(ErrorNoNet);
        }
    }
    else {
        //内购被禁用
        self.payFail(ErrorPayUnabel);
    }
}

// didFinishLaunchingWithOptions
- (void)addObserver{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

// Called when the application is about to terminate
- (void)removeObserver{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
