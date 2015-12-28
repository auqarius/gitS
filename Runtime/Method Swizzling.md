# Method Swizzling

**这篇文章其实可以算是我的笔记，因为很多地方和原文章都很像。主要是为了让自己理解，如果你觉得会看不懂，可以建议看看[原文][原文连接]。**

*Swizzling: [SWIZ] 骗局*

先来回顾一下，在 Runtime 基础里面说的 Method:

	typedef struct objc_method *Method;

objc_method 的定义:

	struct objc_method {
    	SEL method_name                                          OBJC2_UNAVAILABLE;
    	char *method_types                                       OBJC2_UNAVAILABLE;
    	IMP method_imp                                           OBJC2_UNAVAILABLE;
	}															 OBJC2_UNAVAILABLE;


可以看到，一个方法，里面有 

* name：SEL 类型，方法的名字
* types: char* ，参数类型
* IMP: 方法的实现函数

而，Method Swizzling 所要做的，就是替换一个方法的实现。在消息和消息转发中，提到了在自己能控制源码的情况下的动态方法修改，而 Method Swizzling 就是在不能看到源代码的情况下，修改一个方法的实现。

我们再看看 IMP

	typedef id (*IMP)(id, SEL, ...);

它是一个函数指针，所以，如果可以让这个指针指向另外一个地址，那就能做到改变一个方法的实现了。当然，不用真的去操作指针，Runtime 提供了一些方法。

这是来自 [NSHipster][1] 的[例子和代码][2]：设想一种情况，来了这么一个需求：希望能记录下每一个页面在 app 中被点开的次数。

第一种方法：在每一个 viewController 里面添加跟踪代码，但是会产生很多重复的代码。

第二种方法：继承，但是我们要继承 UIViewCOntroller、UITableViewCOntroller、UINavigationController 等其他的 viewController。也会重复很多代码。

如果用 Method Swizzling ，那就方便多了：

	#import <objc/runtime.h>
	
	@implementation UIViewController (Tracking)
	
	+ (void)load {
		static dispatch_once_t onceToken;
		dispath_once(&onceToken, ^{
			// 获取类
			Class class = [self class];
			
			// 获取 SEL
			SEL originalSelector = @selector(viewWillAppear:);
			SEL swizzledSelector = @selector(my_viewWillAppear:);
			
			// 获取 Method
			Method originalMethod = class_getInstanceMethod(class, originalSelector);
			Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
			
			// When swizzling a class method, use the following:
			// 翻译：如果是想改类方法，就用下面的代码:
			// Class class = object_getClass((id)self)
			// ...
			// Method originalMethod = class_getClassMethod(class, originalSelector);
			// Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
			
			// 将 my_viewWillAppear 的实现添加到 @selector(viewWillAppear:)
			BOOL didAddMethod = class_addMethod(class,
									originalSelector,
									method_getImplementation(swizzedMethod), 
									method_getTypeEncoding(swizzledMethod));
									
			if (didAddMethod) {
				// 将 viewWillAppear 的实现替换到 @selector(my_viewWillAppear:)
				class_replaceMethod(class,
					swizzledSelector,
					method_getImplementation(originalMethod),
					method_getTypeEncoding(originalMethod));
			} else {
				// 如果没添加成功，就直接将两个方法的 IMP 互换
				method_exchangeImplementtations(originalMethod, swizzledMethod);
			}
		});
	}
	
	#pragma mark - Method Swizzling 
	
	- (void)my_viewWillAppear:(BOOL)animated {
		[self my_viewWillAppear];
		// track
	}
	
	@end
	

上面的代码实现了什么应该很容易看明白。首先说明一下，Swizzling 应该在 +load 方法中实现 +load 方法是在一个类最开始加载的时候调用。当然这个替换只能进行一次，如果多次进行，到时候就全乱了，所以 dispatch_once 是必须的，但是也有人说 [+load 方法本来就是线程安全的，所以不加也可以][3]。

有两个问题：

1. [self class] 和 objc_getClass((id)self)区别， [self class] 获取的是 self 的类，而 objc_getClass((id)self)过去的是 self 的元类。[这里有解释这个事情][5]。
2. 在最后 my_viewWillAppear 中又调用了 my_viewWillAppear 是否会造成递归调用而陷入死循环？答案是不会的，因为在调用 [self my_viewWillAppear] 最后走的实现是什么？是已经替换过的 viewWillAppear 的实现。


Method Swizzling 有一些需要注意的：

1. 应该在 +load 方法里实现这个操作；
2. 最好在修改方法的时候调用继承的父类方法；
3. 注意不要命名冲突
4. 调用 my_viewWillAppear 其实会调用旧的 viewWillAppear 方法；
5. 多个 Swizzling 的顺序，多个有继承关系的对象 swizzle 的时候，应该先从父类开始，这样才能保证子类调用父类的时候拿到正确的实现；
6. 不容易理解，因为确实看起来像递归；
7. 不容易 debug。

[这篇博客][4]详细讲解了以上内容。



# 结语

关于 Objc Runtime 就到此为止了，前前后后研究了有一个多月，而且是在一年前研究过一次的情况下，现在才稍微搞明白，这到底是什么东西，和它的操作原理。是我太笨了呢...不过还好搞明白了。后面会做一些关于 Runtime 的例子，这样能对 Runtime 的使用有更深刻的理解。





















[1]: http://nshipster.com/
[2]: http://nshipster.com/method-swizzling/
[3]: http://stackoverflow.com/questions/5371601/how-do-i-implement-method-swizzling
[4]: http://blog.csdn.net/yiyaaixuexi/article/details/9374411
[5]: http://stackoverflow.com/questions/15906130/object-getclassobj-and-obj-class-give-different-results
[原文连接]: http://yulingtianxia.com/blog/2014/11/05/objective-c-runtime/