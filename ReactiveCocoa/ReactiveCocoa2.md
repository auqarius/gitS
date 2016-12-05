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

总得来说，函数式编程就是一个表达式，y = x + 1， 就像数学中的函数一样。

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

* Stream就是一个 按时间排序的Events(Ongoing events ordered in time)序列 ，它可以emit三种不同的Events：(某种类型的)Value、Error或者一个"Completed" Signal。

* 监听一个Stream也被称作是 订阅(Subscribing)，而我们所定义的函数就是观察者(Observer)，Stream则是被观察者(Observable)，其实就是观察者模式(Observer Design Pattern)。

理解了以上两篇文章以后，对于 ReactiveCocoa 的理解就会简单很多了。


## ReactiveCocoa 实现

在上一个章节中了解到，ReactiveCocoa 实现了 FRP，也了解了什么是 FRP。再温习一下，FRP 的关键点在于：

1. Stream
2. Subscribe

再次来看一下一个 Stream 的整个订阅过程：

![StreamImage](https://s-media-cache-ak0.pinimg.com/564x/9d/e3/f8/9de3f880e3d8499e975e73441edf78c2.jpg)

而对于 ReactiveCocoa 来说，其重点实现为：

1. RACStream：对应响应式中的 Stream，它是一个 Monad。
2. RACSubscriber：做订阅动作的订阅者。
3. RACSignal：RACStream 在 ReactiveCocoa 中只是一个流的抽象，而 RACSignal 以及其类簇才是真正实现功能的地方。
4. RACDisposable：当一个订阅者结束订阅的时候，需要将在订阅的时候创建的数据清除或者将创建的其他任务结束，约等于收尾工作。
5. RACScheduler：封装了 GCD，用来控制任务在什么时候什么位置执行。在订阅的一个 Signal 的时候，RACScheduler 将创建 RACSignal 的时候传入的 block 放在了线程中执行。

看起来是比纯粹的 RP 订阅过程要复杂一些，其实重点还是 `RACSignal` 和 `RACSubscriber` 其他的东西都是围绕这这俩进行的，先看一下 Reactivecocoa 整个订阅过程：
 


