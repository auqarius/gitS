# 链式语法

在 Objective-C 中，我们调用方法的方式一般都是使用 `[]`，阅读和使用其实还可以接受。但是当 Swift 出现以后，点语法完全代替了中括号，看起来非常优雅，非常棒。（当然很多其他的语言也都是这样调用的。）

由俭入奢易，由奢入俭难，当接触了更加优雅的代码，之前的方式就感觉心里不爽，要是让 Objective-C 可以这样调用方法就好了。

于是想到了 Masonry ，其链式语法让人受益良多，其中最关键的部分就是使用点语法调用方法。

## 使用点语法调用方法

Objective-C 里面，调用方法是可以使用点语法的，但这仅限于没有参数的方法。

使用点语法调用带参数的方法，最关键的一环就是 block。

这里有 [一篇文章讲解 block](https://onevcat.com/2011/11/objc-block/) 非常好，其中最关键的一句：

> block就是一个代码块，但是它的神奇之处在于在内联(inline)执行的时候还可以传递参数。同时block本身也可以被作为参数在方法和函数间传递。

明白了不？把 block 当作一个特殊的变量，在方法里面传来传去，这个变量的特殊点在于其本身也可以传递参数和返回数据。

下面先看一个简单的例子：

```
// Chain.h

typedef void(^MethodBlock)(NSString *string);

@interface Chain : NSObject

- (void)getChainName:(MethodBlock)block;

@end
```
这里，Chain 这个类定义了一个 block ，这个 block 会传递一个 NSString 类型的参数。来看看实现：

```
// Chain.m

- (void)getChainName:(MethodBlock)block {
    if (block) {
        block(_chainName); // _chainName 是自己定义的一个 ivar
    }
}
```

在使用的时候：

```
// SomeOtherFile.h

Chain *chain = [[Chain alloc] init];
[chain getChainName:^(NSString *string) {
	NSLog(@"ChaniName: %@", string);
}];
```

上面的用法是将 block 作为参数在方法和函数间传递，是一个最经典的 "正向" 使用，这一过程完全可以反过来，使用者和声明者的用法反过来。下面来做一个设置 chainName 的方法：

```
// Chain.h

- (MethodBlock)setChainName;
```
对于 Chain 这个类，设定一个方法来设置 chainName，但是为了点语法调用，不能要参数，将 block 作为返回值，将整个过程反过来，可以达到非常棒的效果。先看看实现：

```
// Chain.m

- (MethodBlock)setChainName {
    return ^void (NSString *string) {
        _chainName = string; // _chainName 是自己定义的一个 ivar
    };
}
```
上面的这个实现，变成了第一个例子的使用方式，而在使用的时候：

```
// SomeOtherFile.h

Chain *chain = [[Chain alloc] init];

chain.setChainName(@"kral");

[chain getChainName:^(NSString *string) {
	NSLog(@"ChaniName: %@", string);
}];
```
看来做到了使用点语法调用方法并传递参数了！

## 链式语法

在上面一个章节的例子里，就只是单一的设置了 Chain 的名字，现在想设置一下长度，可是不想写：

```
chain.setChainName(@"Kral");
chain.setChainLength(@"1000m");
```
链式语法么，最好能连起来。

别忘了 block 也是可以写返回值的，还记得上面定义的 MethodBlock 吗：

```
typedef void(^MethodBlock)(NSString *string);

```
它没有返回值，如果把它的返回值设置成一个 Chain ，就可以不停的将这个对象传来传去了。

```
// Chain.h

// 改成这样
typedef Chain *(^MethodBlock)(NSString *string);
```
然后再定义一个设置长度的方法：

```
// Chain.h

- (MethodBlock)setChainLength;
```
看看修改后的实现：

```
- (MethodBlock)setChainName {
    return ^Chain* (NSString *string) {
        _chainName = string;
        return self;
    };
}

- (MethodBlock)setChainLength {
    return ^Chain* (NSString *string) {
        _chainLength = string;
        return self;
    };
}
```
现在调用：

```
chain.chainName(@"kral");
```
 
 这句代码现在有返回值了，就是那个 chain，那就可以再次调用新方法了：
 
 ```
 chain.setChainName(@"kral").setChainLength(@"1000m");
 
 ```
 把设置名字和长度的方法名改一下：
 
 ```
 - (MethodBlock)name;

- (MethodBlock)length;
 ```
 那么调用就变成了：
  
 ```
 chain.name(@"kral").length(@"1000m");
 ```
 恩，完美！
 
#总结

以上的例子，其实只是一个引子，只要脑洞够大，能灵活的运用，这种思维是可以有更远的发展。

不过在平常的使用中，这种用法并不是推荐的，想要维护这样一个类或者一个大量使用的项目，还是比较麻烦的。如果真的想要优雅，还是写 Swift 吧。

对了，链式语法在 Objective-C 中是利用 block 实现的，用 block 的话，大家应该都知道，一定要避免循环引用。









