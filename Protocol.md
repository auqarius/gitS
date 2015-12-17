#协议和代理

例如 有 class OneViewController, 有 class TwoViewController

然后 TwoViewController 有一个方法是

```
- (int)maxA:(int)a B:(int)b;
```

是用来计算两个值的大小的，返回的数字是 a、b 中大的那一个。

然后在 OneViewController 里面，有一个方法:

```
- (void)caculateMax {
	int a = 10;
	int b = 12;
	TwoViewController *two = [[TwoViewController alloc] init];
	int c = [two maxA:a B:b];
}
```

这是在 OneViewController 类中，实例化了 TwoViewController 类，然后调用了 TwoViewController 的方法，并使用了这个方法的结果。
我想这个你都知道，你也经常用。


那么我想问，如果这个时候想在 TwoViewController 里面用 OneViewController 的方法怎么办？
就是说，我们想让一段代码在 OneViewController 里面运行，然后在把返回值传给 TwoViewController 这个实例，并且 TwoViewController 还能传几个参数过来。
怎么实现？

就在上面的例子中，使用一种东西就可以完成，叫做代理。
代理是一种协议，协议又是什么呢？

就像两个人定协议一样，比如我和你定协议，我订了协议，所有遵守我这个协议的人只能按照协议里说的办事。
比如我说遵守协议的人不能吃早饭，那如果你注册了我的协议，那么你就不能吃早饭，除非你取消注册我的协议。

两个类也一样，A 类定义了协议，B 类就要实现用 A 类定义在协议内的方法。就跟我说你不能吃早饭，你要实现一样。

在上面的例子里面，如果要实现： “如果这个时候想在 TwoViewController 里面用 OneViewController 的方法怎么办？”

我们给 TwoViewController 写一个协议，然后让 OneViewController 去遵守 TwoViewController 的协议，不就好了。
我相信你还是挺迷糊的。看看下面的代码应该就不会这么迷糊了。

按照刚才的思路，我们首先要给 TwoViewController 写一个协议，写在 TwoViewController.h:

```
// 给 TwoViewController 定义协议
@protocol TwoViewControllerDelegate <NSObject>
// 代理方法
- (int)maxA:(int)a B:(int)b;

@end

@interface TwoViewController : UIViewController

// 给 Two 写代理,这个代理必须遵守 TwoViewControllerDelegate 这个协议
@property (nonatomic, assign) id <TwoViewControllerDelegate> delegate ;
- (int)maxA:(int)a B:(int)b;

@end
```

其实我们写这个代理，应该你也能看懂方法要干什么，我们要遵守协议的一方给我们提供一个方法来判断a、b 的大小。
那我们就要在 TwoViewController 里面用这个。我是这样用的：

```
- (int)maxA:(int)a B:(int)b {
// 当有人遵循这个代理的时候，我们就用它
if ([self.delegate respondsToSelector:@selector(maxA:B:)]) {
  	 return [self.delegate maxA:a B:b];
}
if (a >= b) {
   	return a;
} else {
   	return b;
}
}
```

然后我们必须要找一个愿意遵循这个协议的人，就让 OneViewController 来做。在 OneViewController.m 里面：

```
// 遵循 Two 的协议
@interface OneViewController () <TwoViewControllerDelegate>

@end


- (void)viewDidLoad {
[super viewDidLoad];
    
self.view.backgroundColor = [UIColor blackColor];
    
TwoViewController *two = [[TwoViewController alloc] init];
// 设置 Two 的代理是 One
two.delegate = self;
    
NSString *answer = [NSString stringWithFormat:@"%d", [two maxA:10 B:20]];
}
	
#pragma mark - TwoViewControllerDelegate
//  One 实现 Two 的代理
- (int)maxA:(int)a B:(int)b {
 	if (a >= b) {
	   return a;
 	} else {
 	  	return b;
	}
}
```

这样，OneViewController 就遵循 Two 的代理，并且实现了！

以上，就是代理、协议。

对了，我还写了一个项目，其实就是一个小例子，点击下载：[栗子~][1]


[1]:http://pan.baidu.com/s/1o6nJ8wU

