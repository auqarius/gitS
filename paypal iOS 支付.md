#PayPal usage in iOS

最近面试了一家公司，是做跨境电商的，刚拿到 offer。在面试的时候聊到过，因为是做跨境电商的，面向的用户群体是美国欧洲的用户，所以在支付环节不使用支付宝/微信支付等国内产品，使用的是 paypal，所以提前研究一下并且先记录下来。

这里是 paypal iOS SDK 的 github 地址：[https://github.com/paypal/PayPal-iOS-SDK][1]

其实只要好好看这里的内容，很容易就能懂。

## 简介

在 paypal 的世界里，他有多种支付方式：

* 直接支付(single payment)：类似国内支付产品，直接对一件或多件商品使用 paypal 余额支付
* 预支付(future payment)：创建一个预支付订单，可能以后进行支付
* 信用卡支付(credit card)：paypal SDK 提供了一套 card.io 的库，可以扫描信用卡，并且使用信用卡直接支付

大多数情况下我们只需要使用直接支付就好。以下也只谈直接支付，其他方式请自行[查看文档][3]。

当然，在支付之前，我们都需要去它的[开发者网站][2]进行开发者申请，创建 application 并获取 `CLIENT_ID_FOR_PRODUCTION` 和 `CLIENT_ID_FOR_SANDBOX`。
### Client ID for Production & Sandbox
OK，其实 paypal 只需要一个 client id 来确认你的 App，那么为什么有 production 和 sandbox 两个呢？

* production：所谓的正式环境，用户需要输入自己的 paypal 账户名和密码来进行支付。
* sandbox：所谓的测试环境，在你注册好账户并且生成 application 之后，paypal 会给你创建一个测试环境和账户，你需要在支付的时候输入这个账户名和密码就可以进行测试了。

### 支付流程
在 iOS 下，paypal 的支付流程可谓是简单，比起支付宝的等，开发者不需要很多复杂的操作，比如密钥什么的，这个最讨厌。你只需要使用 paypal SDK 创建好支付的内容，然后跳转到 paypal SDK 提供的 PayPalPaymentViewController，然后用户去完成支付就 OK 了，也不需要用户安装 paypal。接着你用代理来监控用户是不是支付成功，或者失败，并且及时通知你的服务器。

## 添加 paypal SDK 到你的项目

如果你用 cocoapods 来管理你的三方库，那么你只需要以下两行代码：

	platform :ios, '6.0'
	pod 'PayPal-iOS-SDK'

如果你不使用 cocoapods，那么请看[这里][4]。

下面不管你有没有使用 cocoapods，都需要给 URL Scheme 里面加以下几行:

	com.paypal.ppclient.touch.v1
	com.paypal.ppclient.touch.v2
	org-appextension-feature-password-management

在文档里面还说了，要添加开源的允许证书，不过怎么弄还没研究过，看了一下，好像不太影响使用，后面研究明白了再加上来 `?????????` 在这里标记一下。

## 怎样支付?

首先这里是直接支付 (single payment) 的[文档][5]。

### paypal 做什么？

1. 推出 paypal 支付视图展示支付信息
2. 和 paypal 合作完成支付
3. 返回支付结果给你的 App

### 你做什么？

1. 接收 paypal 的支付结果
2. 发送支付结果给你的后台服务器
3. 给用户提供货物或者服务

当然你还以选择提供给 paypal 一个邮寄地址，paypal 会保存下来这个地址。

## 示例代码

1. 初始化 SDK，需要你提供 client ID，这个过程在 AppDelegate.m 里面实现。
	
		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
		{
		  // ...
		  [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction : @"YOUR_CLIENT_ID_FOR_PRODUCTION",
		                                                         PayPalEnvironmentSandbox : @"YOUR_CLIENT_ID_FOR_SANDBOX"}];
		  // ...
		  return YES;
		}
		
2. 在你的结算页面添加代理
	
		// SomeViewController.h
		#import "PayPalMobile.h"

		@interface SomeViewController : UIViewController<PayPalPaymentDelegate>
		// ...
		@end
		
3. 创建一个 `PayPalConfiguration` 对象，这个对象将表示在这个页面的支付类型、展示语言、是否可用信用卡、商户名称等。

		// SomeViewController.m

		@interface SomeViewController ()
		// ...
		@property (nonatomic, strong, readwrite) PayPalConfiguration *payPalConfiguration;
		// ...
		@end

		@implementation SomeViewController

		- (instancetype)initWithCoder:(NSCoder *)aDecoder {
		  self = [super initWithCoder:aDecoder];
		  if (self) {
		    _payPalConfiguration = [[PayPalConfiguration alloc] init];

		    // See PayPalConfiguration.h for details and default values.
		    // Should you wish to change any of the values, you can do so here.
		    // For example, if you wish to accept PayPal but not payment card payments, then add:
		    _payPalConfiguration.acceptCreditCards = NO;
		    // Or if you wish to have the user choose a Shipping Address from those already
		    // associated with the user's PayPal account, then add:
		    _payPalConfiguration.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
		  }
		  return self;
		} 
		
4. 建立支付环境，然后和 paypal 服务器进行预连接。建议是在这个页面初始化的时候就建立预连接，但是最好不要直接建立连接，因为这个连接是有时间限制的。

		// SomeViewController.m

		- (void)viewWillAppear:(BOOL)animated {
		  [super viewWillAppear:animated];

		  // Start out working with the test environment! When you are ready, switch to PayPalEnvironmentProduction.
		  [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentNoNetwork];
		}
		
5. 创建 `PayPalPayment` 对象，它必须要设置：价格、汇率代码、简介、交易意图（sale、order、authorize），当然包括可选属性：发票号和邮寄地址。

		// SomeViewController.m

		- (IBAction)pay {

		  // Create a PayPalPayment
		  PayPalPayment *payment = [[PayPalPayment alloc] init];

		  // Amount, currency, and description
		  payment.amount = [[NSDecimalNumber alloc] initWithString:@"39.95"];
		  payment.currencyCode = @"USD";
		  payment.shortDescription = @"Awesome saws";

		  // Use the intent property to indicate that this is a "sale" payment,
		  // meaning combined Authorization + Capture.
		  // To perform Authorization only, and defer Capture to your server,
		  // use PayPalPaymentIntentAuthorize.
		  // To place an Order, and defer both Authorization and Capture to
		  // your server, use PayPalPaymentIntentOrder.
		  // (PayPalPaymentIntentOrder is valid only for PayPal payments, not credit card payments.)
		  payment.intent = PayPalPaymentIntentSale;

		  // If your app collects Shipping Address information from the customer,
		  // or already stores that information on your server, you may provide it here.
		  payment.shippingAddress = address; // a previously-created PayPalShippingAddress object

		  // Several other optional fields that you can set here are documented in PayPalPayment.h,
		  // including paymentDetails, items, invoiceNumber, custom, softDescriptor, etc.

		  // Check whether payment is processable.
		  if (!payment.processable) {
		    // If, for example, the amount was negative or the shortDescription was empty, then
		    // this payment would not be processable. You would want to handle that here.
		  }

		  // continued below... 
		  
6. 创建然后展示 `PayPalPaymentViewController` 页面，使用之前创建好的 `PayPalPayment` 和 `PayPalConfiguration`。

		// Create a PayPalPaymentViewController.
		  PayPalPaymentViewController *paymentViewController;
		  paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment
		                                                                 configuration:self.payPalConfiguration
		                                                                      delegate:self];

		  // Present the PayPalPaymentViewController.
		  [self presentViewController:paymentViewController animated:YES completion:nil];
		  
7. 当然不要少了代理方法的监听。

		// SomeViewController.m

		#pragma mark - PayPalPaymentDelegate methods

		- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController
		                 didCompletePayment:(PayPalPayment *)completedPayment {
		  // Payment was processed successfully; send to server for verification and fulfillment.
		  [self verifyCompletedPayment:completedPayment];

		  // Dismiss the PayPalPaymentViewController.
		  [self dismissViewControllerAnimated:YES completion:nil];
		}

		- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
		  // The payment was canceled; dismiss the PayPalPaymentViewController.
		  [self dismissViewControllerAnimated:YES completion:nil];
		}

8. 给你的服务器发送支付成功、支付失败等信息请求。
	
		// SomeViewController.m

		- (void)verifyCompletedPayment:(PayPalPayment *)completedPayment {
		  // Send the entire confirmation dictionary
		  NSData *confirmation = [NSJSONSerialization dataWithJSONObject:completedPayment.confirmation
		                                                         options:0
		                                                           error:nil];

		  // Send confirmation to your server; your server should verify the proof of payment
		  // and give the user their goods or services. If the server is not reachable, save
		  // the confirmation and try again later.
		}
		
## 最后

别被骗了，如果是直接支付，一定要[确认一下支付的证明][6]。这一步骤应该是服务器来确定。服务器需要将你收到的支付 id 给 paypal 进行验证。

[1]:https://github.com/paypal/PayPal-iOS-SDK
[2]:https://developer.paypal.com/webapps/developer/applications
[3]:https://github.com/paypal/PayPal-iOS-SDK/tree/master/docs
[4]:https://github.com/paypal/PayPal-iOS-SDK#add-the-sdk-to-your-project
[5]:https://github.com/paypal/PayPal-iOS-SDK/blob/master/docs/single_payment.md
[6]:https://developer.paypal.com/webapps/developer/docs/integration/mobile/verify-mobile-payment/