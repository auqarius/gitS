# 消息

在 Objective-C Runtime 基础里面，是从发送一个消息展开的，那发送一个消息（在 OC 中是调用一个方法）的过程到底是怎样的，还是要先从 objc_msgSend 函数说起，

## objc_msgSend 函数

	objc_msgSend(id self, SEL op, ...)


消息发送的时候，并不是简单的查询类中的 methodList 而是有一个步骤来优化这个过程：

1. 检测这个 selector 是不是要忽略的，比如有了 RAC 就不用理会 retain, release 函数了。
2. 检测这个 target 是不是要忽略的。 Objective-C 的特性是允许对一个 nil 对象执行任何一个方法不会 crash，因为会忽略掉。
3. 现在才开始，查找这个类的 IMP，前面提到过 cache，先从 cache 里面找。
4. 如果 cache 里面找不到，，就去找方法分发表，就是 `struct objc_method_list **methodLists` 。
5. 如果本类的方法分发表找不到，就去超类的方法分发表去找，一直找到 NSObject 为止。
6. 如果还是找不到，就要开始进入动态方法解析了，后面会提到。

编译器会根据情况在以下几中方法中选择方法调用：

* objc_msgSend：本类调用，返回值为简单值。
* objc_msgSend_stret：本类调用，返回值为结构体。
* objc_msgSendSuper: 超类调用，返回值为简单值。
* objc_msgSendSuper_stret: 超类调用，返回值为结构体。
* objc_msgSend_fpret: **特别的：在 i386 平台处理返回类型为浮点数的时候使用。**

PS: stret = **st**ruct + **ret**urn; fpret = **f**loating-**p**oint **ret**urn

## 方法中的隐藏参数

self 是我们经常使用的一个关键字，它用来引用实例本身，但是为什么 self 就能取到调用当前方法的对象呢？其实 self 的内容是在方法运行时被偷偷的动态传入的。

当 objc_msgSend 找到方法对应的实现的时候，它直接调用该方法实现，并将消息中所有的参数都传递给方法实现，同时，它还将传递两个隐藏的参数：

* 接收消息的对象（也就是 self 指向的内容）
* 方法选择器 （_cmd 指向的内容）

之所以说它们是隐藏的，是因为在源代码方法的定义中并没用声明这两个参数。它们是在代码被编译时被插入实现中的。尽管没有被明确声明，我们在写代码的时候仍然可以使用它们。下面的例子中，self 引用了接受者对象，而 _cmd 引用了当前方法本身的选择器：

	- strange {
		id target = getReceiver();
		SEL method = getTheMethod();
		
		if (target == self || method == _cmd) {
			return nil;
		}
		return [target performSelector:method];
	}

self 是在方法实现中访问消息接受者兑现过的实例变量的途径。
super 是代码中常用的另一个关键字，当这个关键字收到消息的时候，编译器会创建一个 objc_super 结构体:

	struct objc_super { id receiver; Class class; };

这个结构体致命了消息应该被传递给特定超类的定义，但是，receiver 仍然是 self 本身。
如果我们想要通过 `[super class]` 获取超类时，编译器会转换为： 

	objc_msgSend(super, @selector(class)) 
	
而这里的 super 其实就是 objc_super 这个结构体的 receiver,等同于:

	objc_msgSend(objc_super.receiver‚ @selector(class))
	
因为 class 方法只有在 NSObject 中才有，所以会触发:

	objc_msgSendSuper(objc_super.receiver, @selector(class))
	
到最后，class 会调用： object_getClass() 获取类，不过这里的 receiver 其实就是 self 本身。

总的来说，相当于我们调用了 [self class]。所以 [super class] 永远获取到的都是 self 的类型。

## 获取方法的地址

上面讲过，调用一个方法，到运行时变为发送一个消息，而这个消息需要经过很多步骤来找到，大部分正常情况下，这都是没有问题的，但是如果我们要重复调用一个方法很多次，如果能避开这些步骤，直接找到 IMP ，就是方法的地址，直接调用，那么效率将会提高很多。

还记得 IMP 的定义么：

	typedef id (*IMP)(id, SEL, ...);

NSObject 有一个 methodForSelector: 实例方法，我们可以用它来获取某个方法对应的 IMP，
	
	void (*initMethod)(id, SEL);
	initMethod = (void (*)(id, SEL))[self methodForSelector:@selector(init)];
	for (int i = 0; i < 1000; i++) {
		initMethod(self, @selector(init));
	}
	
注意： methodForSelector: 方法是由 Cocoa 的 Runtime 提供的，不是 Objc 自身的特性。

## 动态方法解析

当 Runtime 系统在 cache 和 methodList 中找不到要执行的方法的时候，Runtime 会调用 resolveInstanceMethod: 或 resolveClassMethod: 来给大家一次机会动态添加方法实现的机会。我们需要用 `class_addMethod` 函数完成向特定类添加特定方法实现的操作：

	 void dynamicMethodIMP(id, self, SEL _cmd) {
	 	// 实现
	 }
	 
	 + (BOOL)resolveInstanceMethod:(SEL)aSEL {
	 	if (aSEL == @selector(resolveThisMethodDtnamically)) {
	 		class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
	 		return YES;
	 	}
	 	return [super resolveInstanceMethod:aSEL];
	 }
	 
上面的例子为 resolveThisMethodDynamically 方法添加了实现内容，也就是 dynamicMethodIMP 方法中的代码。其中 "V@:" 表示返回值和参数，v 代表 void，@ 代表一个  object，: 代表 SEL。更多此类符号请看： [Type Encoding][1]

注意：动态方法解析会在消息转发机制前执行，如果你想让这里直接到达消息转发机制中，那么就让 resolveInstanceMethod: 返回 NO。

## 消息转发

### 重定向
动态方法解析 (resolveInstancemethod) 完成后，如果返回 YES，那将完成消息发送，如果返回 NO，那将进入到消息转发，消息转发是一个非常耗时的过程，所以， Runtime 在动态方法解析失败后会给我们一个机会来再次弥补错误：通过重载 `- (id)forwardingTargetForSelector:(SEL)aSelector` 方法替换消息的接受者，为其他对象：

	- (id)forwardingTargetForSelector:(SEL)aSelector {
		if (aSelector == @selector(mysteriousMethod:)) {
			retutrn alertnateObject;
		}
		return [super forwaidingTargetForSelector: aSelector];
	}

这个方法，返回 nil 或者 self 会进入消息转发机制（forwardInvocation:），整个过程如下图:



![消息转发图片]

### 转发

当重定向操作失败后，消息转发机制会被触发，这是 forwardInvocation: 方法会被执行，可以重写这个方法来定义我们的转发逻辑：

	- (void)forwardInvocation:(NSInvocation *)anInvocation {
		if ([someOtherObject respondsToSelector:[anInvocation selector]]) {
			[anInvocation invokeWithTarget:someOtherObject];
		} else {
			[super forwardInvocation:anInvocation];
		}
	}

这个参数 anInvocation 是一个 NSInvocation 类型的对象，它封装了原始的消息和消息的参数。我们可以实现forwardInvocation: 方法来对一些不能处理的消息做一些处理，也可以转发给其他对象来处理，而不抛出错误。
在 forwardInvocation: 消息发送之前，Runtime 系统会向该对象发送 methodSignatureForSelector: 消息，将需要发送的消息封装成 NSInvocation 对象，所以在重写 forwardInvocation: 的同时也要重写 methodSignatureForSelector: 方法，否则会抛出异常。

forwardInvocation: 方法是从 NSObject 继承下来的，但是 NSObject 只是简单的调用了doesNotRecognizeSelector: ，所以如果有需求，我们要自己实现消息转发，将消息转发给其他对象。

### 转发与继承

尽管我们可以通过转发来让一个类接收一个不属于自己的消息而不 crash，但是这不代表这个消息就属于这个类，在调用 respondsToSelector: 方法的时候依然不能返回 YES。
当然你也可以重写 respondsToSelector: 方法来让它返回 YES。





[1]:https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
[消息转发图片]:http://7ni3rk.com1.z0.glb.clouddn.com/QQ20141113-1@2x.png?imageView2/2/w/800/q/75|watermark/2/text/eXVsaW5ndGlhbnhpYQ==/font/Y29taWMgc2FucyBtcw==/fontsize/500/fill/I0VGRUZFRg==/dissolve/100/gravity/SouthEast/dx/10/dy/10