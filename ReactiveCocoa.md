
#ReactiveCocoa
## kvo
```  
// 当self.username改变，都会输出一遍。  
[RACObserve(self, username) subscribeNext:^(NSString *newName) {
NSLog(@"%@", newName);
}];
```
### 带条件的kvo
```
// 当self.username改变，如果名字是以j开头的，则输出名字，否则不输出。 
[[RACObserve(self, username) filter:^(NSString *newName) {
return [newName hasPrefix:@"j"];}] subscribeNext:^(NSString *newName) {
NSLog(@"%@", newName);
}];
```
## 条件控制
```
// 方法+combineLatest:reduce: 可以接收一个数组的信号，在这里creatEnabled 的真假是由self.password和self.passwordConfirmation是否一样来控制的。
RAC(self,createEnabled)=[RACSignal combineLatest:@[RACObserve(self,password),RACObserve(self,passwordConfirmation)] reduce:^(NSString *password, NSString *passwordConfirm) {
return @([passwordConfirm isEqualToString:password]);}];
```

## 事件调用
### button的点击事件
```
// 可以监控button的点击事件。	
self.button.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id_){
NSLog(@"button was pressed!");
return [RACSignal empty];
}];
```
### 异步网络请求
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
<i class="icon-file"></i> singles 可以代表timers、大部分的UI事件、或者其他的总是在变的东西

### 信号的多个异步事件监控
```
// 当[client fetchUserRepos], [client fetchOrgRepos]均返回信号才会执行log
[[RACSignal merge:@[[client fetchUserRepos],[client fetchOrgRepos]]] subscribeCompleted:^{
NSLog(@"They're both done!");
}];
```



