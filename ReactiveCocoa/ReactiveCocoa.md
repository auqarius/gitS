
#ReactiveCocoa
@(iOS学习笔记)[翻译]
> 其他资料：`希望你优先查看其他资料`<br>
> 1. 简介：[ReactiveCocoa in NSHipster][1]<br>
> 2. 概念1： [ReactiveCocoa与Functional Reactive Programming][4]<br>
> 3. 概念2：[说说ReactiveCocoa 2][5]<br>
> 4. 实战：[ReactiveCocoa2实战][6]

**目录**

[TOC]

## kvo代替
---------

```  
// 当self.username改变，都会输出一遍。  
[RACObserve(self, username) subscribeNext:^(NSString *newName) {
NSLog(@"%@", newName);
}];
```
## 带条件的kvo
---------

```
// 当self.username改变，如果名字是以j开头的，则输出名字，否则不输出。 
[[RACObserve(self, username) filter:^(NSString *newName) {
return [newName hasPrefix:@"j"];}] subscribeNext:^(NSString *newName) {
NSLog(@"%@", newName);
}];
```
## RAC条件控制
---------

```
// 方法+combineLatest:reduce: 可以接收一个数组的信号，在这里creatEnabled 的真假是由self.password和self.passwordConfirmation是否一样来控制的。
RAC(self,createEnabled)=[RACSignal combineLatest:@[RACObserve(self,password),RACObserve(self,passwordConfirmation)] reduce:^(NSString *password, NSString *passwordConfirm) {
return @([passwordConfirm isEqualToString:password]);}];
```

## button的点击事件
---------

```
// 可以监控button的点击事件。	
self.button.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id_){
NSLog(@"button was pressed!");
return [RACSignal empty];
}];
```
## 异步网络请求
---------

```
// 可以自定一个事件(RACCommand),例如self.loginCommand,然后将事件调用的代码写在block里面。
self.loginCommand = [[RACCommand alloc] initWithSignalBlock:^(id sender)
{
// 当登陆请求完成后logIn方法返回一个信号。
return [client logIn];
}]; 
// 给登陆好以后加事件
[self.loginCommand.executionSignals subscribeNext:^(RACSignal*loginSignal){
// 登陆好以后输出成功
[loginSignal subscribeCompleted:^{
NSLog(@"Logged in successfully!");
}];
}];

// 将button的点击事件设置为自定义的事件
self.loginButton.rac_command = self.loginCommand;
```
<i class="icon-file"></i> **signals 可以代表timers、大部分的UI事件、或者其他的总是在变的东西**

## 信号的多个异步事件监控
---------

```
// 当[client fetchUserRepos], [client fetchOrgRepos]均返回信号才会执行log
[[RACSignal merge:@[[client fetchUserRepos],[client fetchOrgRepos]]] subscribeCompleted:^{
NSLog(@"They're both done!");
}];
```

## 多个异步信号顺序执行
---------

```
// 登陆后然后缓存用户信息
// loginUser是登陆代码，会返回用户信息类User
// -flattenMap: 在前面的方法发送一个signal值的时候会执行后面block中的代码
// 然后会将block中返回的signal合并成一个新的单独的RACSignal
[[[[client logInUser] flattenMap:^(User *user){
// 缓存User
return [client loadCachedMessagesForUser:user];
}] flattenMap:^(NSArray *messages){
return [client fetchMessagesAfterMessage:messages.lastObject];
}] subscribeNext:^(NSArray *newMessages){
NSLog(@"New messages: %@", newMessages);
} completed:^{
NSLog(@"Fetched all messages.");
}];
```

##RAC绑定异步执行结果
---------

```
// 创建一个单项绑定，这样就可以在用户登录的第一时间设置用户的头像到self.imageView.image，fetchUserWithUsername方法返回一个用户的signal。deliverOn方法创建一个新的signal到其他的线程工作。map将会在每一次fetchUserWithUsername返回信息的时候执行一遍block。
RAC(self.imageView, image) = [[[[client fetchUserWithUsername:@"joshaber"] deliverOn:[RACScheduler scheduler]] map:^(User *user) {
// 下载头像图片（这个时候是在其他线程中执行的）
return [[NSImage alloc] initWithContentsOfURL:user.avatarURL];
}]
// 现在，RAC将在主线程中执行
deliverOn:RACScheduler.mainThreadScheduler];
```


> 上面的例子只能展示出这个东西到底能干什么，但是不能表明出它的强大支出。
> 如果需要更多的示例代码，请查看[C-41][2]这个项目。
> [更多RAC的文档][3]






[1]: http://nshipster.cn/reactivecocoa/
[2]:https://github.com/AshFurrow/C-41
[3]:https://github.com/ReactiveCocoa/ReactiveCocoa/blob/swift-development/Documentation
[4]:http://limboy.me/ios/2013/06/19/frp-reactivecocoa.html
[5]:http://limboy.me/ios/2013/12/27/reactivecocoa-2.html
[6]:http://limboy.me/ios/2014/06/06/deep-into-reactivecocoa2.html