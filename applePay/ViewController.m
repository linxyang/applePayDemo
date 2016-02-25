//
//  ViewController.m
//  applePay
//
//  Created by Yanglixia on 16/2/25.
//  Copyright © 2016年 Yanglinxia. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *productView;

@property (weak, nonatomic) IBOutlet UIView *payView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.判断当前设备是否支持applePay功能
    if (![PKPaymentAuthorizationViewController canMakePayments]) {
        
        // 要iphone6以上的设备才能支持支付功能
        NSLog(@"当前设备不支持applePay功能");
        
        // 隐藏payView
        self.payView.hidden = YES;
        
        
        // 判断是否添加了银行卡。iOS9.2才开始对中国开放，支持银联卡。8.0时支持visa卡。
        /*
         extern NSString * const PKEncryptionSchemeECC_V2 NS_AVAILABLE_IOS(9_0);
         
         extern NSString * const PKPaymentNetworkAmex NS_AVAILABLE(NA, 8_0);
         extern NSString * const PKPaymentNetworkChinaUnionPay NS_AVAILABLE(NA, 9_2);
         extern NSString * const PKPaymentNetworkDiscover NS_AVAILABLE(NA, 9_0);
         extern NSString * const PKPaymentNetworkInterac NS_AVAILABLE(NA, 9_2);
         extern NSString * const PKPaymentNetworkMasterCard NS_AVAILABLE(NA, 8_0);
         extern NSString * const PKPaymentNetworkPrivateLabel NS_AVAILABLE(NA, 9_0);
         extern NSString * const PKPaymentNetworkVisa NS_AVAILABLE(NA, 8_0);
         */
    } else if (![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:@[PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay]]) {
        
        
        // 创建一个添加按钮到payView中，当用户点击时，中转到添加银行卡界面
        /*
         PKPaymentButtonType如下：
         PKPaymentButtonTypePlain = 0,
         PKPaymentButtonTypeBuy,
         PKPaymentButtonTypeSetUp NS_ENUM_AVAILABLE_IOS(9_0)
         
         PKPaymentButtonStyle如下：
         PKPaymentButtonStyleWhite = 0,
         PKPaymentButtonStyleWhiteOutline,
         PKPaymentButtonStyleBlack
         */
        PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeSetUp style:PKPaymentButtonStyleWhiteOutline];
        // PKPaymentButton 继承自UIButton
        [button addTarget:self action:@selector(jumpToAddCardBtnClick) forControlEvents:UIControlEventTouchUpInside];
        //把按钮添加到payView中
        [self.payView addSubview:button];
        
        
        // 已经添加了银行卡
    } else {
        //创建一个购买按钮,当用户点击了按钮时，购买一个商品
        PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleBlack];
        [button addTarget:self action:@selector(buyBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.payView addSubview:button];
    }
    
}


// 跳转到添加银行卡
- (void)jumpToAddCardBtnClick
{
    NSLog(@"按钮被点击了");
    PKPassLibrary *pkpassLibrary = [[PKPassLibrary alloc] init];
    // 打开设置界面去添加银行卡
    [pkpassLibrary openPaymentSetup];

}

// 购买按钮点击了
- (void)buyBtnClick
{
    NSLog(@"购买商品，开始支付");
    
    // 1.创建一个支付请求
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    
    // 1.1 配置商家ID
    request.merchantIdentifier = @"merchant.com.applePay.merchantname";
    
    // 1.2 配置货币代码，以及国家代码
    request.currencyCode = @"CNY";
    request.countryCode = @"CN";
    
    // 1.3 配置请求支持的支付网络
    request.supportedNetworks = @[PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay];
    
    // 1.4 配置商户的处理方式
    /*
     PKMerchantCapability3DS                                 = 1UL << 0,   // Merchant supports 3DS
     PKMerchantCapabilityEMV                                 = 1UL << 1,   // Merchant supports EMV
     PKMerchantCapabilityCredit NS_ENUM_AVAILABLE_IOS(9_0)   = 1UL << 2,   // Merchant supports credit
     PKMerchantCapabilityDebit  NS_ENUM_AVAILABLE_IOS(9_0)   = 1UL << 3    // Merchant supports debit
     */
    // PKMerchantCapability3DS：官方文档中说明，必须支持此方式
    request.merchantCapabilities = PKMerchantCapability3DS;
    
    // 1.6 配置购买的商品列表
    NSDecimalNumber *price1 = [NSDecimalNumber decimalNumberWithString:@"10666"];//代表价格为10666元
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:@"MacBookPro" amount:price1];
    
    NSDecimalNumber *price2 = [NSDecimalNumber decimalNumberWithString:@"1334"];//代表价格为1334元
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem summaryItemWithLabel:@"iPhone4s" amount:price2];
    
    NSDecimalNumber *totalPrice = [NSDecimalNumber decimalNumberWithString:@"20000"];//共价20000元
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem summaryItemWithLabel:@"深圳***网络科技有限公司" amount:totalPrice];
#warning 支付列表最后一个，表示汇总，一般写自己公司名字作为商品名，价格为汇总的价格。
    request.paymentSummaryItems = @[item1,item2,item3];
    
    // 前面的配置均为必选项，不然程序会崩溃
    
    // 2 配置请求的附加项
    // 2.1 配置是否显示发票的收货地址，显示哪些选项
    /*
     PKAddressFieldNone                              = 0UL,      // No address fields required.
     PKAddressFieldPostalAddress                     = 1UL << 0, // Full street address including name, street, city, state/province, postal code, country.
     PKAddressFieldPhone                             = 1UL << 1,
     PKAddressFieldEmail                             = 1UL << 2,
     PKAddressFieldName NS_ENUM_AVAILABLE_IOS(8_3)   = 1UL << 3,
     PKAddressFieldAll
     */
    request.requiredBillingAddressFields = PKAddressFieldAll;
    
    // 2.2 是否显示快递地址，显示哪些选项,参数同上。
    request.requiredShippingAddressFields = PKAddressFieldAll;
    
    // 2.3 配置快递方式:NSArray<PKShippingMethod *>
    NSDecimalNumber *priceForJD = [NSDecimalNumber decimalNumberWithString:@"0.0"];//免费
    PKShippingMethod *methodForJD = [PKShippingMethod summaryItemWithLabel:@"京东快递" amount:priceForJD];
    //必须设置一个标志符以区别快递
    methodForJD.identifier = @"JD";
    methodForJD.detail = @"24小时内送到";
    NSDecimalNumber *priceForSF = [NSDecimalNumber decimalNumberWithString:@"15.0"];//15块
    PKShippingMethod *methodForSF = [PKShippingMethod summaryItemWithLabel:@"顺风快递" amount:priceForSF];
    methodForSF.identifier = @"SF";
    methodForSF.detail = @"两天内送到";
    request.shippingMethods = @[methodForJD,methodForSF];
    
    // 2.4 配置快递的类型
    /*
     PKShippingTypeShipping,
     PKShippingTypeDelivery,
     PKShippingTypeStorePickup,
     PKShippingTypeServicePickup
     */
    request.shippingType = PKShippingTypeStorePickup;
    
    // 2.5 添加一些附加数据，系统没有的.
    request.applicationData = [@"buyID=123456789" dataUsingEncoding:NSUTF8StringEncoding];
    
    // 3.验证用户的支付授权
    PKPaymentAuthorizationViewController *authorizationVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
    
    // 4 设置授权控制器的代理
    authorizationVC.delegate = self;
    
    // 4.弹出授权界面
    [self presentViewController:authorizationVC animated:YES completion:nil];
    
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

/**
 *  如果授权成功就会来到此方法，必须实现该方法。
 *
 *  @param controller 授权控制器
 *  @param payment    支付对象（订单信息，快递方式等等信息）
 *  @param completion 回调，在里面告诉系统当前的支付状态是否成功
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    // 一般在此处，拿到支付信息，然后发给我们的服务器处理，处理完毕之后，服务器会返回一个状态告诉我们是否支付成功。最后我们根据支付成功与否做相应的处理。
    BOOL isSuccess = YES;//模拟
    if (isSuccess) {
        /*
         PKPaymentAuthorizationStatusSuccess, // Merchant auth'd (or expects to auth) the transaction successfully.
         PKPaymentAuthorizationStatusFailure, // Merchant failed to auth the transaction.
         
         PKPaymentAuthorizationStatusInvalidBillingPostalAddress,  // Merchant refuses service to this billing address.
         PKPaymentAuthorizationStatusInvalidShippingPostalAddress, // Merchant refuses service to this shipping address.
         PKPaymentAuthorizationStatusInvalidShippingContact,       // Supplied contact information is insufficient.
         
         PKPaymentAuthorizationStatusPINRequired NS_ENUM_AVAILABLE(NA, 9_2),  // Transaction requires PIN entry.
         PKPaymentAuthorizationStatusPINIncorrect NS_ENUM_AVAILABLE(NA, 9_2), // PIN was not entered correctly, retry.
         PKPaymentAuthorizationStatusPINLockout NS_ENUM_AVAILABLE(NA, 9_2)    // PIN retry limit exceeded.
         */
        completion(PKPaymentAuthorizationStatusSuccess);//告诉系统，支付成功
    } else {
        completion(PKPaymentAuthorizationStatusFailure);//支付失败
    }

}


// 授权结束时调用，必须实现。
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    
    NSLog(@"授权结束");
    // dismiss授权控制器
    [controller dismissViewControllerAnimated:YES completion:nil];
}



@end
