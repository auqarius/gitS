#RectiveCocoa

## kvo

	// 当self.username改变，都会输出一遍。
	
	[RACObserve(self, username) subscribeNext:^(NSString *newName) {
    NSLog(@"%@", newName);
	}];

## 带条件的kvo
	// 当self.username改变，如果名字是以j开头的，则输出名字，否则不输出。
	
	[[RACObserve(self, username)
    filter:^(NSString *newName) {
        return [newName hasPrefix:@"j"];
    }]
    subscribeNext:^(NSString *newName) {
        NSLog(@"%@", newName);
    }];

## 条件控制
	// +combineLatest:reduce: 可以接收一个数组的信号，在这里self.creatEnabled 的true/false 是由self.password和self.passwordConfirmation是否一样来控制的。
	
	RAC(self, createEnabled) = [RACSignal 
    combineLatest:@[ RACObserve(self, password), RACObserve(self, passwordConfirmation) ] 
    reduce:^(NSString *password, NSString *passwordConfirm) {
        return @([passwordConfirm isEqualToString:password]);
    }];
    
## 事件调用
### button的点击事件
	// 可以监控button的点击事件。
	
	self.button.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    NSLog(@"button was pressed!");
    return [RACSignal empty];
	}];

### 异步网络请求
	// 