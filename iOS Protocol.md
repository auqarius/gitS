# iOS 里的 Protocol

协议 (Protocol) 是一个非常灵活的东西，它考验着开发者的抽象能力，按照思路，用起来还是很好用的。

但 Objective-C 中的使用真的是很少，用的最多的就是 Delegate 了，这也是苹果官方用的最多的方式。

这都源自于 Objective-C 最初的设计思路，也许并没有希望 Protocol 发挥很大的作用(纯属个人臆测)。

在 Swift 中，协议终于成为了主力队员，相关内容可以[查看这篇文章](http://www.cocoachina.com/swift/20150803/12881.html)。

## Protocol

Protocol 仅仅是一种声明，它可以声明方法、属性，然后在需要的类中遵循它。

```
@protocol SomeProtocol <NSObject>

@required;
@property (nonatomic, copy) NSString *property;

@optional;
- (void)method;

@end

```
首先，protocol 是可以继承的，它继承自 `<NSObject>` 协议，Objective-C 真是把面向对象里面的继承已经做的深入骨髓。

其次，protocol 是可以声明属性和方法的，如果声明了属性，在使用这个协议的时候，类的实现里面需要自己去实现 setter getter 方法，当然也可以 `@synthesize` 来自动生成。

`@required;` 是必须实现的意思，如果遵循了这个协议，就必须实现其下方的方法和属性。不然会在调用的时候导致 Crash。

`@optional` 非必须实现。

看看最基础的 NSObject 类，它就遵循 `<NSObject>` 协议，一些基础的抽象属性和方法都在里面：

```
@protocol NSObject

- (BOOL)isEqual:(id)object;
@property (readonly) NSUInteger hash;

@property (readonly) Class superclass;
- (Class)class OBJC_SWIFT_UNAVAILABLE("use 'anObject.dynamicType' instead");
- (instancetype)self;

- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)object;
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

- (BOOL)isProxy;

- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;

- (BOOL)respondsToSelector:(SEL)aSelector;

- (instancetype)retain OBJC_ARC_UNAVAILABLE;
- (oneway void)release OBJC_ARC_UNAVAILABLE;
- (instancetype)autorelease OBJC_ARC_UNAVAILABLE;
- (NSUInteger)retainCount OBJC_ARC_UNAVAILABLE;

- (struct _NSZone *)zone OBJC_ARC_UNAVAILABLE;

@property (readonly, copy) NSString *description;
@optional
@property (readonly, copy) NSString *debugDescription;

@end

```

而 NSObject 类是这样声明的：

```
@interface NSObject <NSObject>

```
不难发现，很多方法比如 `- (BOOL)isEqual:(id)bject;`、`- (instancetype)self` ，其实都是这个协议提供的，还有一些常用的基础属性。

以上这些基础性的东西，可以看到，protocol 其实是**一组类和方法的声明**，可以使用一个 Protocol，灵活的给不同的类添加某些特性。

## 基本使用

上面说了，Protocol 这东西在抽象方面可以有比较大的作用。就拿最常用的例子，Person 来举例，可以设定一个 `<Person>` 协议：


```
@protocol Person <NSObject>

@required;
// 名字
@property (nonatomic, copy) NSString *name;

@optional;
// 头衔
@property (nonatomic, copy) NSString *title;

@end

```
对于一个人来说，名字是必须的，但是头衔选择的，这样很合理。

创建一个 Person 类，遵循这个协议：

```
@interface Person : NSObject <Person>

@end

```
于是这个 Person 类就很自然的有名字了。

就像上面说过的：

定义在 `interface` 中的属性，Objective-C 会自动帮助我们实现 setter 和 getter ，但是 protocol 不行，需要自己实现，当然，也可以使用 `@synthesize` 关键字来自动添加：

```
@implementation Person

@synthesize name;

// Methods

@end
```
这样就可以当做一个正常属性来使用了。在使用的时候，需要注意这个类是否实现了对应的属性或者方法。

```
Person *person = [[Person alloc] init];
if ([person respondsToSelector:@selector(setName:)]) {
	person.name = @"Kral";
}

```

所以在基类里面尽量都要实现这些 Procotol，在上面的例子里，为了不 Crash，最好也实现 title 的 setter 和 getter。

如果再创建一个类继承自 Person，比如 Student，也可以在 Student 里面重新实现这两个属性的 setter 和 getter，添加更多操作。

## 在创建对象的时候指定 Protocol

在很多三方库里面，为了不暴露使用的类，会建议使用者这样创建对象：

```
id <Person> person = [[Person alloc] init];
```

这样创建出来的 person 可以直接使用 `<Person>` 协议中的属性和方法。

## Delegate

代理是我们最常用的 Protocol 方法，其实就是上面两种使用方式的组合。假设一个 Student 类和 Teacher 类，一个老师会管理很多学生，然后学生完成作业以后老师需要批改。

举个例子，这个老师就管一个学生。那么我们的思路如下：

1. 创建一个 Student 类

	* 声明一个协议 `StudentDelegate`， 协议中声明一个完成作业的方法 `didFinishHomework`
	* 一个遵循这个协议的属性作为代理 `delegate`
	* 再给 Student 类添加一个做作业的方法 `doHomework`，调用做作业的方法，将执行做作业的操作，然后完成后再调用 `delegate` 的 `didFinishHomework` 方法
2. 创建一个 Teacher 类

	* import "Student.h"
	*  一个 Student 类型的属性 kral 
	*  kral.delegate = self
	*  然后在放学后调用 Student 的 `doHomework` 
	
直接看代码：

```
// Student.h

@class Student;
// 声明协议
@protocol StudentDelegate <NSObject>

@required;
// 完成作业
- (void)student:(Student *)student didFinishHomework:(NSString *)homework;

@end

@interface Student : Person

// 一个遵循协议的属性作为代理
@property (nonatomic, weak) id<StudentDelegate> delegate;

// 开始做作业
- (void)doHomework;

@end

``` 

delegate 是一个遵循 `<StudentDelegate>` 协议的任意类型属性，weak 是为了不循环引用，用法类似上面第二种使用方法。看看实现：

```
// Student.m

#import "Student.h"

@implementation Student

- (void)doHomework {
    
    NSString *homeWork = @"";
    
    // doing homework...
    
    if ([self.delegate respondsToSelector:@selector(student:didFinishHomework:)]) {
        [self.delegate student:self didFinishHomework:homeWork];
    }
}

@end
```

self.delegate 就是一个对象而已，它可以执行自己的方法，但是因为要调用的是协议方法，所以要先判定，self.delegate 是不是实现了完成作业方法，然后再调用。

下面看 Teacher 类：

```
// Teacher.h

#import "Student.h"

@interface Teacher : Person <StudentDelegate>

@property (nonatomic, strong) Student *kral;

@end
```
声明 Teacher 一个学生的属性就行了。主要看实现：

```
// Teacher.m

#import "Teacher.h"

@implementation Teacher

- (void)setKral:(Student *)kral {
    _kral = kral;
    self.kral.delegate = self;
}

- (void)afterSchool {
    [self.kral doHomework];
}

#pragma mark - StudentDelegate

- (void)student:(Student *)student didFinishHomework:(NSString *)homework {
    // 批改作业
}

@end
```
kral 的内存管理描述是 Strong，self 又作为 kral 的属性传递过去了，如果这个 delegate 的内存管理描述是 Strong 或者 Retain 那将会导致循环引用，这就是 delegate 设置为 weak 的原因。

然后实现完成作业方法，老师再批改作业就好了。

#总结

很多 iOS 开发者在一开始接触 Protocol 的时候并不是直接接触的，而是通过 Delegate 接触的，并把这种使用形式固化。

这种固定形式是挺好用的，但是 Protocol 到底是什么，这会是个疑问，还是需要去研究清楚的，不然万一出了一些奇奇怪怪的问题都不知道为什么。

先有 Protocol 再有 Delegate，这些是必须搞明白先后，才能灵活使用。

当然，对于其他问题，也应该做到这样。

[这里](http://rypress.com/tutorials/objective-c/protocols)还有一篇关于 Protcol 的讲解，就是直接讲了 Protocol，很有用。
