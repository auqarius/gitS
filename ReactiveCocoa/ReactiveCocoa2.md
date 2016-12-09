# Reactive Cocoa 

## ReactiveCocoa 解决了什么问题

ReactiveCocoa 是一个 iOS 中的函数式响应式编程框架，它改变了我们在使用 Cocoa 时的思维和方式。

它将苹果的 API 进行了一次封装改造，使其可以使用响应式进行编程。

### 函数式编程 (Functional Programming) [FP]

> *注： 本人之前并不了解函数式编程，也是为了深入了解 ReactiveCocoa 为什么会那样写代码才去研究的，了解也比较浅显。有需要了解的同学可以看看这篇文章 : [函数式编程（Functional Programming）简介](http://janfan.github.io/chinese/2015/05/18/functional-programming.html)*

在 iOS 中，开发者一般使用的开发范例都是面向对象开发，而面向对象是一种命令式编程 (Imperative Programming)。它与函数式编程是两种开发思维，其实目的都是一样的，让计算机计算出来我们需要的结果。

> In computer science, functional programming is a programming paradigm—a style of building the structure and elements of computer programs—that treats computation as the evaluation of mathematical functions and avoids changing-state and mutable data.
> 
> 在计算机科学中，函数式编程是一种指定了计算机编程中编程结构和元素的编程范例，将一次计算作为一个数学函数，避免了状态的改变并且不会改变原始数据。

总的来说，函数式编程就是一个表达式，y = x + 1， 就像数学中的函数一样。

比如需要求 1 到 n 的和，用 Swift 来写，在命令式编程中，会写成这样：

```
func addTo(_ number: Int) -> Int {
    var sum: Int = 0
    for i in 1...number {
        sum += i
    }
    return sum
}

addTo(10) // 55
```
addTo() 是有状态的，sum 为一个执行状态，在执行结束的时候程序达到了最终状态，目标达到，结束运行。

而在函数式编程中，代码会是这样：

```
func addUpTo(_ number: Int) -> Int {
    if number >= 1 {
        return number + addUpTo(number-1)
    }
    return number
}

addUpTo(10) // 55
```
函数式编程中不使用循环，想要循环只能使用递归。在 addUpTo() 中是不保存状态的，换个方式，可以说，它是使用了函数来保存状态的。

在函数式编程中，如果仅此而已，那么其表达能力是非常弱的，函数式编程有两个本质：

1. 高阶函数：我们可以将函数作为另外一个函数的参数或者返回值，这样组合下来的函数即为高阶函数。
2. 没有副作用：函数的功能是返回一个新值，没有其他行为，更不能修改外部变量的值，强于计算，弱与 I/O。

当然函数式编程不可能就真的不执行 I/O，但它通过一些手段来把I/O的影响限制到最小，比如通过Continuations, Monad等技术。

### Moand 

> **重点来了：** 说了那么多函数式编程，就是为了引出 Monad，Moand 是将函数连接起来的方法，在函数式编程里是一个比较重要的概念。

1. 在知乎上有一个人回答的关于 [Moand 是什么](https://www.zhihu.com/question/19635359/answer/129696669) 的答案我觉得还是比较合适新手的。
2. 这里还有一个 [讲解 Moand ](http://blog.leichunfeng.com/blog/2015/11/08/functor-applicative-and-monad/) 的版本，在最后联系到了 ReactiveCocoa，非常棒。

Monad 提供了一个 `>>=` 方法，其发音是 bind。通过 bind 可以完成两个函数的绑定，完成一个组合计算。

因为对函数式和 Monad 的理解也不是非常深刻，在这里就不展开了，上面两个链接也只是从茫茫资料中挑选出来好理解的。毕竟是做程序，多敲代码才能更加理解。

在第一个知乎上面的回答中 Monad 的例子，写了一个 Swift 版本，方便理解吧：

```
enum type {
    case ret
    case excp
}

// M 是一个 Monad
struct M <T> {
    init(value: T, t: type) {
        self.value = value
        self.t = t
    }
    var value: T
    var t: type
    
    // 一个辅助 debug 方法
    func log() {
        if t == .ret {
            print(value)
        } else {
            print("Exception")
        }
    }
    
    // 将一个普通值放在一个 M 中
    static func unit (value: T) -> M {
        return M.init(value: value, t: .ret)
    }
    
    // 一个不可用的 M
    static func raise () -> M {
        return M.init(value: 0 as! T, t: .excp)
    }
    
    // >>= 方法
    func selfBind (value: M, morph: ((T) -> M)) -> M {
        if value.t == .excp {
            return M.raise()
        } else {
            return morph(value.value)
        }
    }
    
    // Swift 优化版 >>= 方法
    func bind (morph: ((T) -> M)) -> M {
       return selfBind(value: self, morph: morph)
    }
}

M.unit(value: 8).bind(morph:  {  (v1: Int) -> M<Int> in
    return M.unit(value: 2).bind(morph: {  (v2: Int) -> M<Int> in
        if v2 == 0 {
            return M.raise()
        }
        return M.unit(value: v1/v2)
    })
}).log() // 4

M.unit(value: 8).bind { (v1: Int) -> M<Int> in
    return M.unit(value: 0).bind(morph: { (v2: Int) -> M<Int> in
        if v2 == 0 {
            return M.raise()
        }
        return M.unit(value: v1/v2)
    })
}.log() // Exception
```

### 响应式编程 (Reactive Programming)

响应式编程是 ReactiveCocoa 的主要思想，Monad 是实现这种思想的方式。

> 函数响应式编程(Functional Reactive Programming:FRP)是一种和事件流有关的编程方式，其角度类似EventSoucing，关注导致状态值改变的行为事件，一系列事件组成了事件流。

> FRP是更加有效率地处理事件流，而无需显式去管理状态。

这里也不展开讨论了，下面是两个讲解：

1. [什么是函数响应式编程(Functional Reactive Programming:FRP)](http://www.jdon.com/45581)
2. [PR 入门](https://github.com/benjycui/introrx-chinese-edition#rp入门)

响应式编程 (Reactive Programming) 的关键点在事件流（Stream）：

* 可以用包括Click和Hover事件在内的任何东西创建Data stream，任何东西都可以是一个Stream：变量、用户输入、属性、Cache、数据结构等等。

* 在这个基础上，你还有令人惊艳的函数去combine、create、filter这些Stream。

* Stream就是一个 按时间排序的Events(Ongoing events ordered in time)序列 ，它可以发送三种不同的Events：(某种类型的)Value、Error或者一个"Completed" Signal。

* 监听一个Stream也被称作是 订阅(Subscribing)，而我们所定义的函数就是观察者(Observer)，Stream则是被观察者(Observable)，其实就是观察者模式(Observer Design Pattern)。

理解了以上两篇文章以后，对于 ReactiveCocoa 的理解就会简单很多了。


## ReactiveCocoa 实现

在上一个章节中了解到，ReactiveCocoa 实现了 FRP，也了解了什么是 FRP。再温习一下，FRP 的关键点在于：

1. Stream
2. Subscribe

再次来看一下一个 Stream 的整个订阅过程：

![Stream 订阅过程](https://s-media-cache-ak0.pinimg.com/564x/5a/35/2b/5a352b2c8ea79df647dff9d0c00425aa.jpg)

而对于 ReactiveCocoa 来说，其重点实现为：

1. [RACStream](#RACStream)：对应响应式中的 Stream，它是一个 Monad。
2. [RACSubscriber](#RACSubscriber)：做订阅动作的订阅者。
3. [RACSignal](#RACSignal)：RACStream 在 ReactiveCocoa 中只是一个流的抽象，而 RACSignal 以及其类簇才是真正实现功能的地方。
4. [RACDisposable](#RACDisposable)：当一个订阅者结束订阅的时候，需要将在订阅的时候创建的数据清除或者将创建的其他任务结束，约等于收尾工作。
5. [RACScheduler](#RACScheduler)：封装了 GCD，用来控制任务在什么时候什么位置执行。在订阅的一个 Signal 的时候，RACScheduler 将创建 RACSignal 的时候传入的 block 放在了线程中执行。

看起来是比纯粹的 RP 订阅过程要复杂一些，其实重点还是 `RACSignal` 和 `RACSubscriber` 其他的东西都是围绕这这俩进行的，先看一下 Reactivecocoa 整个订阅过程：
 
![ReactiveCocoa 订阅过程](https://s-media-cache-ak0.pinimg.com/564x/48/d5/0d/48d50d9c27594e72cd31822131725d92.jpg)

解读一下（具体代码在后面）：

1. Create Signal with stream block：创建 [RACSignal](#RACSignal)，需要传入一个 block (这个 block 会带一个 [RACSubscriber](#RACSubscriber) 类型的参数，并返回一个 [RACDisposable](#RACDisposable))， 然后将这个 block 存入属性 `didSubscribe`，在这个 block 中指定数据或者事件流的内容，并指定在某一个状态执行 block 自带的参数 subscriber 的 `sendNext`、`sendError`、`sendComplete` 方法。注意在这一步，只是创建了 RACSignal 其他的东西都没有创建，block 中的代码并未执行，因此，如果没有订阅一个 Signal 那么这个 Signal 将没有任何的数据或事件流，也不存在订阅者；
2. Subscribe：订阅 Signal，调用 signal 的 `subscribeNext...` 方法，指定订阅者对应的 `nextBlock`、`errorBlock`、`completeBlock`，并且执行 `didSubscribe(subscriber)` 这里的 subscriber 就是创建的订阅者；
3. sendNext：sendNext 操作是第二步中创建的 subscriber 调用的；
4. sendError：sendError 操作是第二步中创建的 subscriber 调用的；
5. sendComplete： sendComplete 操作是第二步中创建的 subscriber 调用的；
6. dispose：在创建 RACSignal 的时候，会指定其 RACDisposable，并在第二步的时候将这个 disposable 存入 subscriber，在 subscriber 调用 `sendError`、`sendComplete` 的时候调用 dispose 方法执行清理代码。

### <a name="RACSignal"></a>RACSignal

先来看看 RACSignal 的继承关系：

![RACSignal 继承关系](https://s-media-cache-ak0.pinimg.com/564x/41/9f/3b/419f3bc953aa42a3b20dd9423f786b7e.jpg)

<a name="RACStream"></a>RACStream 是一个 Monad，代表了一个数据或事件流，它声明了 `reutrn` 和 `bind` 方法，实现里面直接返回了 nil，因为它是一个抽象类，我们在用的时候最多使用的是 `RACSignal` 和  `RACSequence`(它也是 RACStream 的子类，可以先不去思考这个)。

```
/// RACStream.h
///
/// A block which accepts a value from a RACStream and returns a new instance
/// of the same stream class.
///
/// Setting `stop` to `YES` will cause the bind to terminate after the returned
/// value. Returning `nil` will result in immediate termination.
typedef RACStream * (^RACStreamBindBlock)(id value, BOOL *stop);

/// An abstract class representing any stream of values.
///
/// This class represents a monad, upon which many stream-based operations can
/// be built.
///
/// When subclassing RACStream, only the methods in the main @interface body need
/// to be overridden.
@interface RACStream : NSObject

/// Lifts `value` into the stream monad.
///
/// Returns a stream containing only the given value.
+ (instancetype)return:(id)value;

/// Lazily binds a block to the values in the receiver.
///
/// This should only be used if you need to terminate the bind early, or close
/// over some state. -flattenMap: is more appropriate for all other cases.
///
/// block - A block returning a RACStreamBindBlock. This block will be invoked
///         each time the bound stream is re-evaluated. This block must not be
///         nil or return nil.
///
/// Returns a new stream which represents the combined result of all lazy
/// applications of `block`.
- (instancetype)bind:(RACStreamBindBlock (^)(void))block;
```
当然 RACSignal 也是一个 Monad，它的功能是通过一系列的类簇来实现的：

1. RACReturnSignal: 实现了 `return` 方法和 `subscribe` （订阅）方法，其订阅方法在订阅的时候会直接调用 `sendNext` 和 `sendComplete` 方法。
2. RACEmptySignal: 实现了 `empty` 方法（可以类比上面 Swift 代码中 `Struct M` 中的 `raise()` 方法）和 `subscribe` （订阅）方法，其订阅方法在订阅的时候会直接调用 `sendComplete` 方法。
3. RACErrorSignal: 实现了 `error` 方法和 `subscribe` （订阅）方法，其订阅方法在订阅的时候会直接调用 `sendError` 方法。在某些时候如果创建 Signal 出错的时候将会被创建，存储了错误信息。
4. RACDynamicSignal: 实现了 `createSignal`、`subscribe` 方法，一个正确可用的 RACSignal 其实是这个类型。
5. <a name="RACSubject"></a>RACSubject: 可以作为一个 `subscriber` 来订阅其他的信号，也可以作为一个信号被订阅。它实现了 [`RACSubscriber`](#RACSubscriberProtocol) 协议中的 `sendNext`、`sendError`、`sendComplete` 方法，它将遍历自己的订阅者，然后依次调用其对应的 `sendNext`、`sendError`、`sendComplete` 方法
	
	* RACBehaviorSubject: 当被订阅的时候，返回其接收的最后一个值。
	* RACGroupedSignal: 分组信号，用来实现信号的分组功能。
	* RACReplaySubject: 重播信号，将信号发送过的值全部保存，被订阅的时候会重新发送这些值，error 和 complete也会被重播。

6. <a name="RACChannelTerminal"></a>RACChannelTerminal: 通道终端，实现 RACChannel 的双向绑定功能。 

#### createSignal:
创建信号的时候需要一个接收订阅者返回清理者的 block（didSubscribe），然后 RACSignal 会将这个 block 作为属性保存起来，并不执行。

```
// RACDynamicSignal.m

+ (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe {
	RACDynamicSignal *signal = [[self alloc] init];
	// didSubscribe 是一个 block，在创建 Signal 的时候实现的，主要作用是指定信号源，确定数据或事件流
	signal->_didSubscribe = [didSubscribe copy];
	return [signal setNameWithFormat:@"+createSignal:"];
}

// 使用：创建信号
RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    // 做一些事情后
    [subscriber sendNext:@1];
    // 任务完成后
    [subscriber sendCompleted];
    // 如果发生错误
    [subscriber sendError:error];
    
    return [RACDisposable disposableWithBlock:^{
        // 清理数据
    }];
}];
```

#### subscribeNext:error:complete:


```
// RACSignal.m 

- (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock error:(void (^)(NSError *error))errorBlock completed:(void (^)(void))completedBlock {
	NSCParameterAssert(nextBlock != NULL);
	NSCParameterAssert(errorBlock != NULL);
	NSCParameterAssert(completedBlock != NULL);
	
	RACSubscriber *o = [RACSubscriber subscriberWithNext:nextBlock error:errorBlock completed:completedBlock];  // RACDynamicSignal
	return [self subscribe:o];
}

// RACDynamicSignal.m
// RACDynamicSignal 只实现了两个方法，第一个是 createSignal，第二个就是 subscribe
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	NSCParameterAssert(subscriber != nil);
	
	// 一组 Disposable，可以理解为一个 Disposable 数组，当被 dispose，他会 dispose 所有它包含的 Disposable
	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
	subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];

	if (self.didSubscribe != NULL) {
		RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
			// 执行创建 signal 的时候保存的 block
			RACDisposable *innerDisposable = self.didSubscribe(subscriber);
			[disposable addDisposable:innerDisposable];
		}];

		[disposable addDisposable:schedulingDisposable];
	}
	
	return disposable;
}
```
###<a name="RACSubscriberProtocol"></a> @protocol RACSubscriber 

RACSubscriber 是一个协议，其他的类可以遵循这个协议并且实现其方法，这样都可以做为一个订阅者。RACSubject 也是遵循了这个协议才可以即作为订阅者又作为信号的。这个协议声明了四个方法：

```
// RACSubscriber.h 

@protocol RACSubscriber <NSObject>
@required

/// Sends the next value to subscribers.
///
/// value - The value to send. This can be `nil`.
- (void)sendNext:(id)value;

/// Sends the error to subscribers.
///
/// error - The error to send. This can be `nil`.
///
/// This terminates the subscription, and invalidates the subscriber (such that
/// it cannot subscribe to anything else in the future).
- (void)sendError:(NSError *)error;

/// Sends completed to subscribers.
///
/// This terminates the subscription, and invalidates the subscriber (such that
/// it cannot subscribe to anything else in the future).
- (void)sendCompleted;

/// Sends the subscriber a disposable that represents one of its subscriptions.
///
/// A subscriber may receive multiple disposables if it gets subscribed to
/// multiple signals; however, any error or completed events must terminate _all_
/// subscriptions.
- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)disposable;

@end
```
前三个方法就不用多说了，是订阅中的最关键的方法。

最后一个方法是添加 Disposable 的，一个订阅者可以订阅多个 Signal，因此它也会收到多个 Disposable，因此是添加方法。注释中也写了，如果触发了 `sendError` 或 `sendComplete` 方法，所有的订阅将也会被终结。

在 ReactiveCocoa 中，实现了 RACSubscriber 协议的类有：

* [RACChannelTerminal](#RACChannelTerminal)
* [RACSubject](#RACSubject)
* RACSubscriber
* RACPassthroughSubscriber

### <a name="RACSubscriber"></a>RACSubscriber 

```
// RACSubscriber.m
// 注意，RACSubscriber 类是在 RACSubscriber+Pirvate.h 中声明的，而实现放在了 RACSubscriber.m 中

+ (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
	RACSubscriber *subscriber = [[self alloc] init];

	subscriber->_next = [next copy];
	subscriber->_error = [error copy];
	subscriber->_completed = [completed copy];

	return subscriber;
}
```

可以看到的是，RACSubscriber 声明了三个属性来存储对应的 block，当然还有 disposable：

```
// RACSubscriber.m

@property (nonatomic, copy) void (^next)(id value);
@property (nonatomic, copy) void (^error)(NSError *error);
@property (nonatomic, copy) void (^completed)(void);

@property (nonatomic, strong, readonly) RACCompoundDisposable *disposable;

```

disposable 是在 init 的时候创建的，当执行 dispose 方法的时候将会把三个 block 置空。

最重要的，RACSubscriber 类实现了 RACSubscriber 协议的方法：

```
// RACSubscriber.m

- (void)sendNext:(id)value {
	@synchronized (self) {
		void (^nextBlock)(id) = [self.next copy];
		if (nextBlock == nil) return;

		nextBlock(value);
	}
}

- (void)sendError:(NSError *)e {
	@synchronized (self) {
		void (^errorBlock)(NSError *) = [self.error copy];
		[self.disposable dispose];

		if (errorBlock == nil) return;
		errorBlock(e);
	}
}

- (void)sendCompleted {
	@synchronized (self) {
		void (^completedBlock)(void) = [self.completed copy];
		[self.disposable dispose];

		if (completedBlock == nil) return;
		completedBlock();
	}
}

- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)otherDisposable {
	if (otherDisposable.disposed) return;

	RACCompoundDisposable *selfDisposable = self.disposable;
	[selfDisposable addDisposable:otherDisposable];

	@unsafeify(otherDisposable);

	// If this subscription terminates, purge its disposable to avoid unbounded
	// memory growth.
	[otherDisposable addDisposable:[RACDisposable disposableWithBlock:^{
		@strongify(otherDisposable);
		[selfDisposable removeDisposable:otherDisposable];
	}]];
}
```
都是最基础的实现，调用对应的 block，添加 disposable。

### RACPassthroughSubscriber

上面在说 RACSubscriber 协议的时候提到：一个订阅者可以订阅多个 Signal。这个类就是完成这个任务的，它有三个属性：

```
// RACPassthroughSubscriber.m

// The subscriber to which events should be forwarded.
@property (nonatomic, strong, readonly) id<RACSubscriber> innerSubscriber;

// The signal sending events to this subscriber.
//
// This property isn't `weak` because it's only used for DTrace probes, so
// a zeroing weak reference would incur an unnecessary performance penalty in
// normal usage.
@property (nonatomic, unsafe_unretained, readonly) RACSignal *signal;

// A disposable representing the subscription. When disposed, no further events
// should be sent to the `innerSubscriber`.
@property (nonatomic, strong, readonly) RACCompoundDisposable *disposable;
```
* innerSubscriber： 用来保存真正的订阅者
* signal：用来保存订阅的 Signal
* disposable：用来保存这个订阅者的 Disposable

重点在于 RACSubscriber 协议的实现（删除了部分代码，只保留了重点代码）：

```
- (void)sendNext:(id)value {
	if (self.disposable.disposed) return;
	[self.innerSubscriber sendNext:value];
}

- (void)sendError:(NSError *)error {
	if (self.disposable.disposed) return;
	[self.innerSubscriber sendError:error];
}

- (void)sendCompleted {
	if (self.disposable.disposed) return;
	[self.innerSubscriber sendCompleted];
}

- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)disposable {
	if (disposable != self.disposable) {
		[self.disposable addDisposable:disposable];
	}
}
```
在这里，先判定了对应的 disposable 是否被销毁过，然后再确定是否触发对应的方法。

### <a name="RACDisposable"></a>RACDisposable

RACDisposable 是 ReactiveCocoa 中的清理者，它在一次订阅结束的时候清理相关数据和任务。

RACDisposable 的继承关系如下：

![RACDisposable 继承关系](https://s-media-cache-ak0.pinimg.com/564x/ef/bf/16/efbf16bd61992386ca17e2982c7d85c3.jpg)

* RACDisposable：在初始化的时候提供一个清理的 block 并保存到属性，在调用 dispose 方法的时候调用这个 block。
* RACKVOTrampoline：RAC 将 KVO 也响应式了，在清理 KVO 的时候使用 RACKVOTrampoline 来做清理，它在创建的时候也使用 KVO 监听了对应的 value，并且在触发的时候做出反应，在 dispose 的时候清理数据，并且解除 KVO 监听。
* RACCompoundDisposable：一系列的清理，使用一个 `CFMutableArrayRef` 来保存所有的 RACDisposable 及其子类，在 dispose 的时候将会 dispose 所有的 RACDisposable；
* RACSerialDisposable：一个含有 Disposable 的 Disposable，内部保存的 Disposable 可以与外部传递来的进行交换。

### <a name="RACScheduler"></a>RACScheduler

RACScheduler 在 ReactiveCocoa 中起了调度的作用，其本质是封装了 GCD 的串行队列，以保证所有相关任务能有序进行。上面有说到，在 RACDynamicSignal subscribe 的时候，会使用 RACScheduler 将创建数据或事件流的 block 放到线程中执行。

RACScheduler 的继承关系如下：

![RACScheduler 继承关系](https://s-media-cache-ak0.pinimg.com/564x/f5/17/a1/f517a136b40b5c70144a3b6eebdd010d.jpg)

* RACImmediateScheduler：立即执行调度的任务。
* RACQueueScheduler：一个抽象的调度者，使用 GCD 队列异步执行其任务。
* RACTargetQueueScheduler：一个可以在任何线程队列执行任务的调度者，在使用队列进行异步执行的时候，都是使用这个类，因为 RACQueueScheduler 只是一个抽象类。
* RACSubscriptionScheduler：执行订阅者相关任务的调度者，他有自己的一个线程，在 ReactiveCocoa 中定义了一个单例来使用。包括上面提到的<mark>*（在 RACDynamicSignal subscribe 的时候，会使用 RACScheduler 将创建数据或事件流的 block 放到线程中执行）*</mark>这个功能就是使用这个单例执行的。

### RACSequence

RACSequence 也是 ReactiveCocoa 中一个比较重要的内容，它继承自 RACStream，但它并不能被当做一个信号被订阅，但它提供一个方法来转换成 signal。

![RACSequence 继承关系](https://s-media-cache-ak0.pinimg.com/564x/c0/81/d0/c081d058402e2c364e71bafb76c9ff80.jpg)

RACSequence 代表的是一个序列，里面的值是有序存放的，这些值不可被改变，像 Objective-C 里面的 collection 类型一样，它不能保存空值。

RACSequence 中最重要的概念是 head 和 tail，就是头和尾巴，头指的是第一个值，尾巴指的是剩下的值，而一个尾巴也是一个 RACSequence，它也有自己的头和尾巴，一个最小的 RACSequence 单元就是尾巴只有一个值。

```
/// The first object in the sequence, or nil if the sequence is empty.
///
/// Subclasses must provide an implementation of this method.
@property (nonatomic, strong, readonly) id head;

/// All but the first object in the sequence, or nil if the sequence is empty.
///
/// Subclasses must provide an implementation of this method.
@property (nonatomic, strong, readonly) RACSequence *tail;
```
RACSequence 存在的目的是为了简化 Objective-C 里面的集合操作，类似 map、filter 等功能，Swift 中的集合是有这样的方法的，但是 Objective-C 没有。

* RACArraySequence： 利用数组 `NSArray` 创建一个 sequence，将数组中的元素按序添加为 sequence 的 head 和 tail，添加了 map、filter 方法。
* RACDynamicSequence：动态实现一个序列，需要提供 `headBlock`、`tailBlock`，在取 head 和 tail 的时候将会调用相关的 block 获取 head 和 tail。
* RACEmptySequence：空序列，实现了 `-empty` 方法，head 和 tail 都是 nil。
* RACIndexSetSequence：利用索引集合 `NSIndexSet` 创建一个 sequence。
* RACSignalSequence：利用 signal 发送过的值创建一个 sequence。
* RACStringSequence：利用 NSString 创建一个 sequence，每一个字符将为一个 head。
* RACTupleSequence：利用元组中的元素创建一个 sequence，使用的是 RACTuple，RACTuple 是 ReactiveCocoa 的元组类，它封装了元组，可以通过方法 `-allObjects` 获取元组中所有的元素。
* RACUnarySequence：单一元素 sequence，tail 为空，用来实现 return 方法。 

### 总结

以上就是 ReactiveCocoa 的来由和基本架构及相关实现了。不过对于函数式和 Monad，还有很多操作，我们的 bind 还没有发挥作用呢，有了 bind 功能，可以实现很多更加自由的东西，比如 map，flattenMap 等功能。ReactiveCocoa 还对 cocoa 的一些接口进行了封装，将一些数据和事件做成了事件流来方便我们使用。

在这里有一个 OC 里面的思路可以学习，就是使用类簇来实现相关功能，类似 `RACScheduler`、`RACSignal`、`RACDisposable`、`RACSubscriber`，都是使用类簇来完成相关功能，每一个子类都是为了完成一个功能，然后使用的时候使用父类来根据不同的功能创建不同的子类。

ReactiveCocoa 相关的内容在研究的时候也参考了不少文章，在这里有一篇写的非常好：

* [ReactiveCocoa 源码解析之架构总览](http://blog.leichunfeng.com/blog/2015/12/25/reactivecocoa-v2-dot-5-yuan-ma-jie-xi-zhi-jia-gou-zong-lan/)

## ReactiveCocoa 进阶

### bind 

最开始在了解 Monad 的时候用 Swift 写的那个 Monad 中，就有一个 bind 方法：

```
// >>= 方法
func selfBind (value: M, morph: ((T) -> M)) -> M {
    if value.t == .excp {
        return M.raise()
    } else {
        return morph(value.value)
    }
}
    
// Swift 优化版 >>= 方法
func bind (morph: ((T) -> M)) -> M {
   return selfBind(value: self, morph: morph)
}

// 使用

M.unit(value: 2).bind(morph: {  (value: Int) -> M<Int> in
        if value == 0 {
            return M.raise()
        }
        return M.unit(value: 100/value)
})
```
可以见得，bind 方法的作用是将 Monad 与一个 block 绑定，这个 block 可以获取到 Monad 中的值，然后对其进行处理，并将处理后的值作为一个新的 Monad 返回。


RACSignal 在实现 bind 方法的时候动作并不多，但是理解起来会很绕，绑定的 block 返回的是一个返回 signal 的 RACStreamBindBlock，bind 方法会返回一个新建的 bindSignal，在新建的 bindSignal 的 createSignalBlock 里面，订阅原信号(self)，并在原信号发送值的时候使用 RACStreamBindBlock 处理值并返回一个持有新值的 newSignal，并且在这个时候订阅这个 newSignal，当这个 newSignal 发送值的时候 bindSignal 也会将这个新值发送出去。在使用 bind 的时候订阅的信号其实是 bindSignal。

```
// 正式看 bind 之前先看看 RACStreamBindBlock 的声明
// RACStream.h

typedef RACStream * (^RACStreamBindBlock)(id value, BOOL *stop);

// RACSignal.m

// bind 方法是必须要返回一个新的 Monad (RACSignal) 的。
- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
	NSCParameterAssert(block != NULL);

	/*
	 * -bind: should:
	 * （-bind: 方法的实现：）
	 * 
	 * 1. Subscribe to the original signal of values.
	 * （1. 订阅原信号的值。）
	 * 2. Any time the original signal sends a value, transform it using the binding block.
	 * （2. 在原信号发送数据的时候，使用绑定的 block 处理这个数据。）
	 * 3. If the binding block returns a signal, subscribe to it, and pass all of its values through to the subscriber as they're received.
	 *（ 3. 如果绑定的 block 返回的是一个信号（RACSignal），将订阅这个信号，然后通过其订阅者将获取到的值发送出去。）
	 * 4. If the binding block asks the bind to terminate, complete the _original_ signal.
	 * （4. 如果绑定的 block 要求绑定结束（使用 RACStreamBindBlock 的 stop 判定），那么完成原信号。）
	 * 5. When _all_ signals complete, send completed to the subscriber.
	 * （5. 当所有绑定的信号都完成了，那么给订阅者发送信号完成。）
	 * 
	 * If any signal sends an error at any point, send that to the subscriber.
	 * （任何绑定的信号在任何时候发送了 error，也将会被发送给订阅者。）
	 */

	//  bind 方法返回的一定是一个新的 RACSignal
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		// 传递进来的参数是一个返回 RACStreamBindBlock 的 block，这里需要的是 RACStreamBindBlock
		RACStreamBindBlock bindingBlock = block();
	
		// 可能绑定的信号不止一个，用这个数组维护所有的绑定信号
		// 每当绑定一个信号，将会将被绑定的信号存入数组
		// 每当有一个信号 complete，那么就在数组中移除这个信号
		// 如果所有的信号都 complete，这个数据也将为空，原信号也将被 complete
		NSMutableArray *signals = [NSMutableArray arrayWithObject:self];
		
		// 与上面的 signals 一样的道理，用来维护所有的信号的 Disposable
		RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
		
		// 完成一个被绑定的信号代码块，将在后面被调用
		void (^completeSignal)(RACSignal *, RACDisposable *) = ^(RACSignal *signal, RACDisposable *finishedDisposable) {
			BOOL removeDisposable = NO;

			@synchronized (signals) {
				[signals removeObject:signal];

				if (signals.count == 0) {
					[subscriber sendCompleted];
					[compoundDisposable dispose];
				} else {
					removeDisposable = YES;
				}
			}

			if (removeDisposable) [compoundDisposable removeDisposable:finishedDisposable];
		};
		
		// 添加一个绑定的信号代码块，将在后面被调用
		void (^addSignal)(RACSignal *) = ^(RACSignal *signal) {
			@synchronized (signals) {
				[signals addObject:signal];
			}
			
			// 被添加的信号将被订阅
			RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
			[compoundDisposable addDisposable:selfDisposable];
			
			// 订阅将原信号发送的值处理后生成的新 signal
			// 当处理后的 signal 发送信号的时候绑定后生成的新 signal 也将调用对应的方法
			RACDisposable *disposable = [signal subscribeNext:^(id x) {
				[subscriber sendNext:x];
			} error:^(NSError *error) {
				[compoundDisposable dispose];
				[subscriber sendError:error];
			} completed:^{
				@autoreleasepool {
					completeSignal(signal, selfDisposable);
				}
			}];

			selfDisposable.disposable = disposable;
		};

		// 真正执行的代码
		@autoreleasepool {
			// 下面会订阅原信号，这个 Disposable 是用来保存当次订阅原信号的 Disposable
			RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
			[compoundDisposable addDisposable:selfDisposable];
			
			// 订阅原信号
			RACDisposable *bindingDisposable = [self subscribeNext:^(id x) {
				// 手动检测原信号的 Disposable 是否 dispose 过，避免同步错误
				// Manually check disposal to handle synchronous errors.
				if (compoundDisposable.disposed) return;

				BOOL stop = NO;
				// 执行绑定的 block，对原信号的 value 进行处理
				id signal = bindingBlock(x, &stop);

				@autoreleasepool {
					// 添加信号
					if (signal != nil) addSignal(signal);
					// 完成信号
					if (signal == nil || stop) {
						[selfDisposable dispose];
						completeSignal(self, selfDisposable);
					}
				}
			} error:^(NSError *error) {
				[compoundDisposable dispose];
				[subscriber sendError:error];
			} completed:^{
				@autoreleasepool {
					completeSignal(self, selfDisposable);
				}
			}];
			
			selfDisposable.disposable = bindingDisposable;
		}

		return compoundDisposable;
	}] setNameWithFormat:@"[%@] -bind:", self.name];
}
```

`-map:` 方法是 RACSignal 中常用的方法，它支持你在原信号发送值的时候修改原值，并返回一个持有这个新值的 signal 提供订阅。这很像 bind 方法，其实它就是封装了 bind 方法的，具体的来说 map 方法调用了 flattenMap 方法，而 flattenMap 方法调用了 bind 方法。

> 注意：在 ReactiveCocoa 中 bind 方法并不建议使用者使用，使用 map / flattenMap 方法即可达到使用者的目的。

### flattenMap

flattenMap 方法允许你提供一个处理原信号发送的值并返回一个任意的 Signal 的 block 作为参数，然后调用 bind 方法，返回一个新的 signal。

```
// RACStream.m

- (instancetype)flattenMap:(RACStream * (^)(id value))block {
	Class class = self.class;

	return [[self bind:^{
		return ^(id value, BOOL *stop) {
			id stream = block(value) ?: [class empty];
			NSCAssert([stream isKindOfClass:RACStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);

			return stream;
		};
	}] setNameWithFormat:@"[%@] -flattenMap:", self.name];
}
```
类比 bind 实现中的参数 block:

```
^{
	return ^(id value, BOOL *stop) {
		id stream = block(value) ?: [class empty];
		NSCAssert([stream isKindOfClass:RACStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);
	
		return stream;
	};
}
```

类比 bind 实现中的 `RACStreamBindBlock bindingBlock`

```
^(id value, BOOL *stop) {
	id stream = block(value) ?: [class empty];
	NSCAssert([stream isKindOfClass:RACStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);
	
	return stream;
};
```

这里类比一下 bind 实现中的参数是为了更加理解 bind，也只有使用了这个方法才能更加理解这个方法是干什么的。

### map

map 方法允许你提供一个处理原信号发送的值并返回新值的 block 作为参数，然后使用 RACSignal 的 `-return:` 方法新建一个与原信号一致的信号，最后返回这个新的 signal。

```
- (instancetype)map:(id (^)(id value))block {
	NSCParameterAssert(block != nil);

	Class class = self.class;
	
	return [[self flattenMap:^(id value) {
		return [class return:block(value)];
	}] setNameWithFormat:@"[%@] -map:", self.name];
}
```
类比 bind 实现中 `void (^addSignal)(RACSignal *)` 代码块中传入的 signal：

```
return [class return:block(value)];
```
在这里，创建这个 signal 的时候并没有调用 `sendNext` 等方法，只是在 bind 实现的时候有订阅这个方法。因为 `[RACSignal return:]` 这个方法，返回的是一个 RACReturnSignal 类型的 signal，这个类型的 signal 在被订阅的时候即时发送值。

> 事实上，在 ReactiveCocoa 中，所有使用 bind 方法的地方，返回的 signal 都是 [RACErrorSignal](#RACErrorSignal)、[RACReturnSignal](#RACReturnSignal)、[RACEmptySignal](#RACEmptySignal) 类型的，这三个类型的 Signal 都自主实现了订阅方法，并在被订阅的时候即时发送值。


还有很多其他方法都是使用 bind 实现的，例如：

```
// 合并多个信号，当其中一个信号发送值的时候，返回的新信号都可以接收到信号，并且发送这个值
// 主要用途在 RACSgianl 的 merge 方法中
- (instancetype)flatten;

// 直接替换原信号发送的值，调用的是 map 方法
- (instancetype)mapReplace:(id)object;

// 筛选原信号发送的值
// block 处理值并返回一个 BOOL 值
// YES 将返回一个持有原值的新 signal
// NO 将返回一个 RACEmptySignal
// 调用了 flattenMap 方法
- (instancetype)filter:(BOOL (^)(id value))block;

// 忽略原信号发送的某个值
// 如果原信号发送的值与 value 相同，则直接忽略
// 调用了 filter 方法
- (instancetype)ignore:(id)value;
```
在这里就不展开分析了，只要了解了 bind 和每个方法的目的，就会很容易理解其操作与使用。

## ReaciveCocoa 对 Cocoa 的封装
ReactiveCocoa 对 Cocoa API 进行了一次封装，在使用的时候，用处比较大的有：

* 代替 `UIControlEvents` 的处理：例如按钮的点击就是 `UIControlEventsTouchUpInside`。
* 代替 delegate 的处理：例如 `UIAlertView` 的点击事件。
* 代替 KVO 的处理

### UIControlEvents

类似 `UIButton` 的点击事件、`UISlider` 、`UIStepper`、`UISwitch`、`UISegmentedControl` 的 valueChanged 事件，总之，在使用的时候，如果一个控件的值改变或者事件触发是根据 `UIControlEvents` 枚举来监听的，都是一种实现方法。

首先 `UIControlEvents` 使用 `-addTarget:action:forControlEvents:` 方法，一般控件的初始化和监控方法是分开的：

```
- (void)addLoginButton {
	UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[loginButton addTarget:self action:@selector(login:) forControlEvents:(UIControlEventTouchUpInside)];
}

- (void)login:(id)sender {
    // login
}
```
而经过 ReactiveCocoa 封装过后的使用方式如下：

```
// UIControlEvents
UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
[[loginButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
    // login
}];
```
封装过后的使用方式更加简便，初始化和事件触发都在一个地方。

ReactiveCocoa 给 UIControl 添加了分类，在这个分类中添加了 `rac_signalForControlEvents:`  的实现，下面是它的实现：

```
// UIControl+RACSignalSupport.h

- (RACSignal *)rac_signalForControlEvents:(UIControlEvents)controlEvents {
	@weakify(self);

	return [[RACSignal
		createSignal:^(id<RACSubscriber> subscriber) {
			@strongify(self);

			[self addTarget:subscriber action:@selector(sendNext:) forControlEvents:controlEvents];
			[self.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
				[subscriber sendCompleted];
			}]];

			return [RACDisposable disposableWithBlock:^{
				@strongify(self);
				[self removeTarget:subscriber action:@selector(sendNext:) forControlEvents:controlEvents];
			}];
		}]
		setNameWithFormat:@"%@ -rac_signalForControlEvents: %lx", self.rac_description, (unsigned long)controlEvents];
}
```
实现过程非常简单：新建一个 RACSignal，依然调用 `-addTarget:action:forControlEvents:` 方法，将 target 设置为订阅者，然后在事件触发的时候调用 `sendNext:` 方法，当 self 被销毁的时候订阅者 `sendComplete`，当这个信号不再被订阅的时候移除监听。

### Delegate 处理

换句话说，协议的处理，或者说，某个方法的调用，我们都可以将其设定成为一个 signal。这个东西在 cocoa 中用处其实一般，但是其实现方法值得学习。

比如我们需要监听 UIAlertView 的 `alertView:clickedButtonAtIndex:` 方法，可以这样写：

```
[[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *args) {
        UIAlertView *alert = args.first;
        NSNumber *index = args.second;
}];
```
这个方法是定义在 `NSObject+RACSelectorSignal.h` 中的，其实这个分类的目的不是为了代理，它提供了两个方法：

```
// NSObject+RACSelectorSignal.h

// 将方法转换为 signal
- (RACSignal *)rac_signalForSelector:(SEL)selector;

// 将协议的方法转换为 signal
- (RACSignal *)rac_signalForSelector:(SEL)selector fromProtocol:(Protocol *)protocol;
```
他们的实现是这样的：

```
// NSObject+RACSelectorSignal.m

- (RACSignal *)rac_signalForSelector:(SEL)selector {
	NSCParameterAssert(selector != NULL);

	return NSObjectRACSignalForSelector(self, selector, NULL);
}

- (RACSignal *)rac_signalForSelector:(SEL)selector fromProtocol:(Protocol *)protocol {
	NSCParameterAssert(selector != NULL);
	NSCParameterAssert(protocol != NULL);

	return NSObjectRACSignalForSelector(self, selector, protocol);
}
```
所以，重点是 NSObjectRACSignalForSelector(selector, protocol) 这个方法的实现，它将一个方法转换成为了 signal。以下为实现，比较复杂：

```
// NSObject+RACSelectorSignal.m

static RACSignal *NSObjectRACSignalForSelector(NSObject *self, SEL selector, Protocol *protocol) {
	// 一个别名方法名
	SEL aliasSelector = RACAliasForSelector(selector);

	@synchronized (self) {
		// 后面会将方法转换为一个 RACSubject，并且使用 runtime 保存为一个属性，key 为别名方法名
		RACSubject *subject = objc_getAssociatedObject(self, aliasSelector);
		// 如果这个方法的对应信号已经创建，那么将不再创建
		if (subject != nil) return subject;
		
		// 重点方法，主要是利用 MethodSwizzle 技术
		// 使用 runtime 新建了一个实现放到了消息转发方法
		// forwardInvocation: 中，在新的实现中：
		// 每次调用都将会把对应的参数使用元组（RACTuple）的方式封装
		// 并且使用 subject 的 sendNext: 方法发送
		// 给一个类添加消息转发方法的时候还必须实现 methodSignatureForSelector: 方法
		// 因此也为这个方法新建了实现
		// 因为也考虑到 selector 方法可能是协议方法，本类中本来并没有实现
		// 为 responseToSelector 方法也创建了一个新的实现
		// 返回一个类型，后面的获取方法等操作都是在这个类下操作的
		Class class = RACSwizzleClass(self);
		NSCAssert(class != nil, @"Could not swizzle class of %@", self);
		
		// 新建 RACSubject 信号，并存储为属性
		subject = [[RACSubject subject] setNameWithFormat:@"%@ -rac_signalForSelector: %s", self.rac_description, sel_getName(selector)];
		objc_setAssociatedObject(self, aliasSelector, subject, OBJC_ASSOCIATION_RETAIN);

		[self.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
			[subject sendCompleted];
		}]];
		
		// 根据方法名在本类中获取方法
		Method targetMethod = class_getInstanceMethod(class, selector);
		if (targetMethod == NULL) {
			// 方法为空，则表示这个方法是 protocol 方法
			// 用来获取方法的参数及返回值类型
			const char *typeEncoding;
			if (protocol == NULL) {
				// 如果没有设定协议，那么这个方法是未定义方法
				typeEncoding = RACSignatureForUndefinedSelector(selector);
			} else {
				// 协议方法
				// Look for the selector as an optional instance method.
				// 获取协议方法描述
				struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
				
				// 检测这个协议是否包含对应的方法
				if (methodDescription.name == NULL) {
					// Then fall back to looking for a required instance
					// method.
					methodDescription = protocol_getMethodDescription(protocol, selector, YES, YES);
					NSCAssert(methodDescription.name != NULL, @"Selector %@ does not exist in <%s>", NSStringFromSelector(selector), protocol_getName(protocol));
				}
				
				// 获取协议方法的参数及返回值类型
				typeEncoding = methodDescription.types;
			}
			
			// 检测这些类型是否都被编码
			RACCheckTypeEncoding(typeEncoding);

			// Define the selector to call -forwardInvocation:.
			// 添加这个方法，并将这个方法的实现指定为消息转发方法 
			if (!class_addMethod(class, selector, _objc_msgForward, typeEncoding)) {
				// 创建不成功的话信号将返回错误
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"A race condition occurred implementing %@ on class %@", nil), NSStringFromSelector(selector), class],
					NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Invoke -rac_signalForSelector: again to override the implementation.", nil)
				};

				return [RACSignal error:[NSError errorWithDomain:RACSelectorSignalErrorDomain code:RACSelectorSignalErrorMethodSwizzlingRace userInfo:userInfo]];
			}
		} else if (method_getImplementation(targetMethod) != _objc_msgForward) {
			// 本类包含的方法，但是不能是消息转发方法
			// Make a method alias for the existing method implementation.
			const char *typeEncoding = method_getTypeEncoding(targetMethod);

			RACCheckTypeEncoding(typeEncoding);
			
			// 添加别名方法，其实现为原方法的实现
			BOOL addedAlias __attribute__((unused)) = class_addMethod(class, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
			NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), class);
			
			// 将原方法的实现替换为消息转发方法的实现
			// Redefine the selector to call -forwardInvocation:.
			class_replaceMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
		}
		
		return subject;
	}
}
```
如果不关心 `RACSwizzleClass ` 方法的实现，这里已经可以解释整个实现过程了，本着问到底的原则，还是要再看看这里的实现：

```
// NSObject+RACSelectorSignal.m

static Class RACSwizzleClass(NSObject *self) {
	// 获取本类的类型，这里用两种方式获取
	// 是因为如果使用类簇开发的，这两个获取的结果不一样
	// statedClass 获取的是调用的类
	// baseClass 获取的是真正创建的类
	Class statedClass = self.class;
	Class baseClass = object_getClass(self);

	// 因为后面将会动态新建一个子类，并将类型保存为本类的属性
	// 如果这个属性存在则返回这个子类
	// The "known dynamic subclass" is the subclass generated by RAC.
	// It's stored as an associated object on every instance that's already
	// been swizzled, so that even if something else swizzles the class of
	// this instance, we can still access the RAC generated subclass.
	Class knownDynamicSubclass = objc_getAssociatedObject(self, RACSubclassAssociationKey);
	if (knownDynamicSubclass != Nil) return knownDynamicSubclass;

	NSString *className = NSStringFromClass(baseClass);
	
	// 如果两个不相等
	// 则表示这个对象使用类簇或者使用其他方式隐藏了本类本来的类型
	if (statedClass != baseClass) {
		// If the class is already lying about what it is, it's probably a KVO
		// dynamic subclass or something else that we shouldn't subclass
		// ourselves.
		//
		// Just swizzle -forwardInvocation: in-place. Since the object's class
		// was almost certainly dynamically changed, we shouldn't see another of
		// these classes in the hierarchy.
		//
		// Additionally, swizzle -respondsToSelector: because the default
		// implementation may be ignorant of methods added to this class.
		@synchronized (swizzledClasses()) {
			// 在实际实现的类上 swizzle 对应的方法
			if (![swizzledClasses() containsObject:className]) {
				RACSwizzleForwardInvocation(baseClass);
				RACSwizzleRespondsToSelector(baseClass);
				RACSwizzleGetClass(baseClass, statedClass);
				RACSwizzleGetClass(object_getClass(baseClass), statedClass);
				RACSwizzleMethodSignatureForSelector(baseClass);
				[swizzledClasses() addObject:className];
			}
		}

		return baseClass;
	}
	
	// 如果这个类就是实现的类
	// 那么将新建一个这个类的子类
	// 这个子类的名字是原类名字后面添加 _RACSelectorSignal 
	// 然后 swizzle 这个子类的对应方法
	// 获取子类名字
	const char *subclassName = [className stringByAppendingString:RACSubclassSuffix].UTF8String;
	// 获取子类
	Class subclass = objc_getClass(subclassName);

	// 如果子类没有创建
	if (subclass == nil) {
		// 创建子类
		subclass = [RACObjCRuntime createClass:subclassName inheritingFromClass:baseClass];
		if (subclass == nil) return nil;
		
		// swizzle 对应方法
		RACSwizzleForwardInvocation(subclass);
		RACSwizzleRespondsToSelector(subclass);

		RACSwizzleGetClass(subclass, statedClass);
		RACSwizzleGetClass(object_getClass(subclass), statedClass);

		RACSwizzleMethodSignatureForSelector(subclass);
		
		// 注册这个类
		objc_registerClassPair(subclass);
	}
	
	// 将本类的类型设置为子类类型
	object_setClass(self, subclass);
	// 将子类保存为属性
	objc_setAssociatedObject(self, RACSubclassAssociationKey, subclass, OBJC_ASSOCIATION_ASSIGN);
	return subclass;
}
```
其实看看也会发现有很多细节，以及 ReactiveCocoa 在实现功能的时候的安全性以及特殊性考虑是非常细致的。这个非常考验开发者对 Cocoa 底层实现细节的理解程度，看这段代码的时候我也是研究了很久才搞明白它在干什么，关于 `self.class` 和 `objc_getClass(self)` 结果不同的原因我也是查了一些资料才搞明白的，想详细了解的可以查看：

* [为什么object_getClass(obj)与[OBJ class]返回的指针不同](http://www.jianshu.com/p/54c190542aa8)

上面一段中，最重要的方法是 `RACSwizzleForwardInvocation ` ，在这里展开说明一下：

```
// NSObject+RACSelectorSignal.m

static void RACSwizzleForwardInvocation(Class class) {
	// 获取原消息转发方法
	SEL forwardInvocationSEL = @selector(forwardInvocation:);
	Method forwardInvocationMethod = class_getInstanceMethod(class, forwardInvocationSEL);

	// 暂存原消息转发方法
	// Preserve any existing implementation of -forwardInvocation:.
	void (*originalForwardInvocation)(id, SEL, NSInvocation *) = NULL;
	if (forwardInvocationMethod != NULL) {
		originalForwardInvocation = (__typeof__(originalForwardInvocation))method_getImplementation(forwardInvocationMethod);
	}

	// 新建一个消息转发方法的实现
	// Set up a new version of -forwardInvocation:.
	//
	// If the selector has been passed to -rac_signalForSelector:, invoke
	// the aliased method, and forward the arguments to any attached signals.
	//
	// If the selector has not been passed to -rac_signalForSelector:,
	// invoke any existing implementation of -forwardInvocation:. If there
	// was no existing implementation, throw an unrecognized selector
	// exception.
	id newForwardInvocation = ^(id self, NSInvocation *invocation) {
		// 发送消息
		BOOL matched = RACForwardInvocation(self, invocation);
		// 如果发送消息成功，则不再有任何处理
		if (matched) return;
		
		// 发送消息失败
		if (originalForwardInvocation == NULL) {
			// 如果原方法不存在，报错，表示这个方法不存在
			[self doesNotRecognizeSelector:invocation.selector];
		} else {
			// 如果原方法存在，则调用原方法
			originalForwardInvocation(self, forwardInvocationSEL, invocation);
		}
	};
	
	// 将原消息转发方法的实现替换为新建的实现
	class_replaceMethod(class, forwardInvocationSEL, imp_implementationWithBlock(newForwardInvocation), "v@:@");
}
```
新建的消息转发方法的实现中，最重要的一段是 `RACForwardInvocation`，在看代码的时候差点吐出血来，居然还要跳一个方法。不过转念想想，毕竟功能不同，写成另一个方法很合适，这也说明了写代码要规范。那么继续看这个方法的实现：

```
// NSObject+RACSelectorSignal.m

static BOOL RACForwardInvocation(id self, NSInvocation *invocation) {
	// 在转换最开始的时候，对于将要被转换为 signal 的 selector
	// ReactiveCocoa 新建了一个别名方法
	// 并且将转换的 signal 使用这个方法的名字当做 key 保存成了属性
	// 取出来这个属性
	SEL aliasSelector = RACAliasForSelector(invocation.selector);
	RACSubject *subject = objc_getAssociatedObject(self, aliasSelector);

	// 先获取消息转发的目标类
	Class class = object_getClass(invocation.target);
	// 如果这个类有这个别名方法
	BOOL respondsToAlias = [class instancesRespondToSelector:aliasSelector];
	if (respondsToAlias) {
		// 设定方法名
		invocation.selector = aliasSelector;
		// 调用这个方法
		[invocation invoke];
	}
	
	// 没有信号，则说明这个方法并没有被转换为 signal
	// 则返回这个类是否存在这个别名方法
	if (subject == nil) return respondsToAlias;
	
	// 将这个 invocation 传递进去的参数封装成 RACTuple 发送出去
	[subject sendNext:invocation.rac_argumentsTuple];
	return YES;
}
```

这样就结束了，关于 RACTuple，它代表了一个元组，是 ReactiveCocoa 自己创建的一个元组类，用来管理元组中的元素。而 `rac_argmentsTuple` 这个方法是 ReactiveCocoa 新建了一个 `NSInvocation` 的分类，将其接收到的参数放到 RACTuple 中。

### 代替 KVO 的处理


