# Masonry 解析

在了解一个开源库之前，我们需要先搞清楚一件事情：

> 这个开源库解决了什么问题？

## Masonry 解决了什么问题？

熟悉的人都知道：

**Masonry 将 NSLayoutConstraint 进行了封装，使用了优雅高效易读的链式语法，让 Objective-C 开发者在手写 Autolayout 的时候不再那么麻烦。**

因此，在看本文之前，你需要知道，[什么是 Autolayout?](http://www.tuicool.com/articles/vQnqeui)

如果你已经知道什么是 Autolayout 了，那你至少还应该知道，[如何使用代码来对视图添加约束?](http://blog.sina.com.cn/s/blog_693de6100102v4sl.html)

现在应该知道，使用代码来写 Autolayout，苹果官方的 API **使用繁琐**，**代码量大**，**不易阅读**。Masonry 非常完美的解决了这个问题。

Masonry 的 Github 地址：[https://github.com/Masonry/Masonry](https://github.com/Masonry/Masonry)

**如果英语能力还可以的话，看它的 Github 里的 Readme 就能看明白很多东西。**

这里有一个如何使用 Masonry 的教程写的不错：[http://adad184.com/2014/09/28/use-masonry-to-quick-solve-autolayout/](http://adad184.com/2014/09/28/use-masonry-to-quick-solve-autolayout/)

## Masonry 如何解决这些问题的？
 
我们先看看 NSLayoutConstraint 的创建方法：

~~~ Objective-C

// UIKit

// NSLayoutConstraint.h

/* Create constraints explicitly.  Constraints are of the form "view1.attr1 = view2.attr2 * multiplier + constant" 
 If your equation does not have a second view and attribute, use nil and NSLayoutAttributeNotAnAttribute.
 */
+(instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1 relatedBy:(NSLayoutRelation)relation toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c; 
 
~~~

看注释里面的，这段代码最终的结果是：

~~~ Objective-C
 
view1.attr1 = view2.attr2 * multiplier + constant
 
~~~

再来看它的使用：
 
~~~ Objective-C
 
// NSLayoutConstraint
[superView addConstraint:[NSLayoutConstraint constraintWithItem:view1
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:superView
                                                      attribute:NSLayoutAttributeTop
                                                     multiplier:1.0
                                                       constant:10]];
// 根据上面的定义，这段代码的结果是：
// view1.top = superView.top * 1.0 + 10;
                                  
// 再看看 Masonry  的做法   
 [view1 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(superview.mas_top).with.offset(10); 
}];                          

// 简直完美！   
                            
~~~
 
Masonry 非常完美的解决了系统提供的复杂使用方式，让写出来的代码简洁，又易懂。
可以思考一下，如果我们要做这样一个封装，该怎么做？

**思路：**

我们首先需要一个类，就像 NSLayoutConstraint 一样，可以管理所有的东西，然后用简洁的输入方式输入所需要的内容，然后再调用一个方法，把需要的参数传递给 NSLayoutConstraint，并且生成，然后添加到 UIView 上。

最好是可以做到这样：

> // 这将是我们的最终目标，请牢记这个，后面我们所有的想法，都是为了这个目标而努力。

>  view1.top = superView.top * 1.0 + 10;

所以我们需要的属性有上面的例子中所需要的所有东西：view1 , top , = , superView , top , 1.0 , 10. 根据 NSLayoutConstraint 的创建方法：

View1 和 superView 是 UIView 类型，

top 是  [NSLayoutAttribute](https://developer.apple.com/reference/uikit/nslayoutattribute)，

= 是 [NSLayoutRelation](https://developer.apple.com/reference/uikit/nslayoutrelation)，

1.0 是乘积， CGFloat 类型，

10 是偏移量 CGFloat 类型，

然后我们可以调用一个方法来完成这个约束的安装。

可是问题来了：

> **这跟系统提供的方法有什么区别呢？**

> **Masonry 是如何实现链式语法的？**

## Masonry 类结构

Masonry 主要的类结构有：

1. **MASConstraint**：继承自 NSObject，是我们上一部分设想的那个类，负责收集 NSLayoutConstraint 的创建方法需要的参数，并给对应的 View 添加 Constraint，不过这个类只是基础的抽象类，只负责收集信息并且提供一些基础方法和属性。

2. **MASViewConstraint**：继承自 MASConstraint，使用 MASViewAttribute 保存 view1 和 superView 与其 NSLayoutAttribute，然后通过一个方法来给 view1 添加约束。

3. **MASViewAttribute**：继承自 NSObject，负责将 view 和 [NSLayoutAttribute](https://developer.apple.com/reference/uikit/nslayoutattribute) 绑定在一起，目的是简化代码，不用在 MASViewConstraint 里面自己维护 view 和 [NSLayoutAttribute](https://developer.apple.com/reference/uikit/nslayoutattribute) 的关系。

4. **MASCompositeConstraint**：继承自 MASConstraint，批量存储 MASConstraint/MASViewConstraint，并提供批量添加约束的方法。

5. **MASLayoutConstraint**：继承自 NSLayoutConstraint，使用系统方法用来做最后的 constraint 生成，多了一个 key 的属性，来做 Debug。

6. **MASConstraintMaker**：继承自 NSObject，最重要的一个类，每个 MASConstraintMaker 维护一个 View，用来处理这个 View 相关的约束，这个 view 每一个相关的约束都是一个 MASViewConstraint，有一个数组 Constraints 来维护这些数据。最后通过一个方法，给 view 批量添加约束。

7. **View+MASAdditions**：因为我们的目标是做到可以直接使用 view.top... 所以我们必须给 UIView 加一个分类来处理这些，其实相关的内容都只是操作 MASConstraintMaker。
 

### <a name= "MASConstraint-ClassRef"></a> MASConstraint : NSObject
 
 这个类是我们设想的最基础的类，按道理它应该负责保存 NSLayoutConstraint 生成方法所需要的所有参数。
 但是 Masonry 没有这么做，Masonry 只把对 view 的 layoutAttribute 使用属性保存了起来：
  
  * NSLayoutConstraint 中的两个枚举类型：[NSLayoutAttribute](https://developer.apple.com/reference/uikit/nslayoutattribute)、 [NSLayoutRelation](https://developer.apple.com/reference/uikit/nslayoutrelation) 
  
  * 乘积 multiplier (CGFloat)
  
  * 偏移量  constant (CGFloat)
  
  * 优先级 UILayoutPriority (float)
  
  * 并且生成了一些其他的衍生属性，比如 offset, insets, sizeOffset, centerOffset, dividedBy 等。

这个类是一个非常标准的抽象类，将基础的数据全部处理掉，然后在 MASConstraint+Private.h 中使用分类 MASConstraint (Abstract) 和一个匿名分类来声明几个基类和子类都将使用到的方法，并且在这里声明代理和代理方法。这一段很有意思，对于开发者来说应该能提供很多灵感。使用分类和协议，能帮你减少很多代码。
  
这里是链式语法的比较关键的一步，就是 `view.top.equalTo(superView.top)` 的 eauqlTo()，我们先看看它是如何定义的：
 
~~~ Objective - C

// MASConstraint.h
/**
 *	Sets the constraint relation to NSLayoutRelationEqual
 *  returns a block which accepts one of the following:
 *    MASViewAttribute, UIView, NSValue, NSArray
 *  see readme for more details.
 */
- (MASConstraint * (^)(id attr))equalTo;
   
~~~

看了就比较明白了，其实它就是将 block 作为返回值，而这个 block 的返回值就是 `MASConstraint` 自己，这样可以继续使用点语法操作其他内容，看看实现：
  
~~~ Objective - C
  
- (MASConstraint * (^)(id))equalTo {
	return ^id(id attribute) {
	    return self.equalToWithRelation(attribute, NSLayoutRelationEqual);
	};
}
  
~~~
 
在这里，`- (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation` 这个方法只是一个抽象的声明而已，因为在 MASConstraint 里面没有涉及到任何的 UIView，因此这些只是概念，具体的实现还是要到 [MASViewConstraint](#MASViewConstraint-ClassRef) 里面。
  
**同理：**
  
~~~ Objective - C
 
- (MASConstraint * (^)(CGFloat offset))offset;
- (MASConstraint * (^)(CGFloat multiplier))multipliedBy;
 
~~~

等等，也是如此的做法。
  
### <a name="MASViewConstraint-ClassRef"></a>MASViewConstraint : MASConstraint
  
当基础类搞定，只能在抽象的意义上设定 view 的 top、left、right、bottom，并没有涉及到具体的 view。在这里就将来完成这一步。对于 NSLayoutConstraint 的生成方法，view 是有顺序的，而且在 NSLayoutConstraint 的属性中，也有 firstItem 、firstAttribute、secondItem、secondAttribute。因此我们也需要这样的东西。不过 Masonry 并没有这么做，它新创建了一个类，叫 [MASViewAttribute](#MASViewAttribute-ClassRef) ，负责将 view 和 attribute 绑定在一起。于是就有了如下属性：
  
  * 第一个视图和它的约束 firstViewAttribute ( [MASViewAttribute](#MASViewAttribute-ClassRef)) 

  * 第二个视图和它的约束 secondViewAttribute ( [MASViewAttribute](#MASViewAttribute-ClassRef))

然后再配一个如下的初始化方法：
  
~~~ Objective - C
 
// MASViewConstraint.h
 
/**
*	initialises the MASViewConstraint with the first part of the equation
*
*	@param	firstViewAttribute	view.mas_left, view.mas_width etc.
*
*	@return	a new view constraint
**/
- (id)initWithFirstViewAttribute:(MASViewAttribute *)firstViewAttribute;
 
~~~
 
还记得我们当初的设想么？
 
~~~ Objective - C
 
view1.top = superView.top * 1.0 + 10;
 
~~~

看看目前为止的代码执行是不是能满足这个要求了：
  
  1. 使用初始化方法，将 view1.top 整合成 MASViewAttribute 类型的实例，并赋值给 firstViewAttribute 属性
  
  2. 代码执行到 view1.top = 的时候，调用 equal 方法

  3. 代码执行到 view1.top = superView.top 的时候，将 superView.top 整合成  MASViewAttribute 类型的实例，并赋值给  secondViewAttribute 属性
  
  4. 代码执行到 view1.top = superView.top*1.0 的时候，将 1.0 保存到 multiplier 属性
  
  5. 代码执行到 view1.top = superView.top*1.0 + 10 的时候，将 10 保存到  constrant 属性
  
完全满足了！然后我们加一个 install (安装) 方法，来调用 NSLayoutConstraint 的创建方法就可以了。
  
这里最重要的实现，就是将 [MASConstraint](#MASConstraint-ClassRef) 里面定义的一些抽象方法具体实现，因为在这里已经有 view、superView 和对应的 NSLayoutConstraint。现在我们可以看看  [MASConstraint](#MASConstraint-ClassRef) 中 `- (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation` 是怎么实现的了:
  
~~~ Objective-C
   
- (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation {
return ^id(id attribute, NSLayoutRelation relation) {
    	if ([attribute isKindOfClass:NSArray.class]) {
    	    // 批量添加
        	NSAssert(!self.hasLayoutRelation, @"Redefinition of constraint relation");
        	NSMutableArray *children = NSMutableArray.new;
        	for (id attr in attribute) {
            	MASViewConstraint *viewConstraint = [self copy];
            	viewConstraint.secondViewAttribute = attr;
            	[children addObject:viewConstraint];
        	}
        	MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
        	compositeConstraint.delegate = self.delegate;
        	[self.delegate constraint:self shouldBeReplacedWithConstraint:compositeConstraint];
        	return compositeConstraint;
    	} else {
    		// 重点
        	NSAssert(!self.hasLayoutRelation || self.layoutRelation == relation && [attribute isKindOfClass:NSValue.class], @"Redefinition of constraint relation");
        	self.layoutRelation = relation;
        	self.secondViewAttribute = attribute;
        	return self;
    	}
	};
}
   
~~~
 
`if` 里面的内容是批量添加的代码，目前来说不是重点。重点看 `else` 里面的内容，其实很简单，只是记录一下。 `self.layoutRelation` 就是 `NSLayoutRelation` 类型的，在 `view1.top = superView.top * 1.0 + 10` 里面负责的是 `=` 的部分，当然也可以是 `>=` 或者 `<=`。
   
**同理：**
  
~~~ Objective - C
 
- (MASConstraint * (^)(CGFloat offset))offset;
- (MASConstraint * (^)(CGFloat multiplier))multipliedBy;
 
~~~

等等，也是如此的做法。
	
offset() 是控制偏移量的，对应的内容是 `+10`，它最终的设置的是 self.layoutConstant。
  
multipliedBy() 是控制倍数的，对应的内容是 `1.0`，它最终的设置的是 self.layoutMultiplier。
  
当然还有很多衍生用法，基本都是来控制这 `self.layoutConstant` 和 `self.layoutMultiplier` 这两个属性的。
   
  
###<a name="MASViewAttribute-ClassRef"></a>MASViewAttribute ： NSObject
  
这个类是用来绑定 view 和 NSLayoutAttribute 的，对于我们的设想，它达到的效果是 view1.top / superView.top， 它的属性有：
  
  * 视图 view (UIView)

  * 约束位置 layoutAttribute (NSLayoutAttribute)

**有了以上这些，我们就可以设置一个视图的某一条约束了：**
  
~~~ Objective - C
  
MASViewAttribute *viewAttribute = [[MASViewAttribute alloc] initWithView:view1 layoutAttribute:NSLayoutAttributeTop];
MASViewConstraint *newConstraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
  
// 先忽略 superView.top 的问题，后面会讲
newConstraint.equalTo(superView.top).offset(10). multipliedBy(1.0);
  
~~~
  
这样已经方便很多了，但是依然需要创建  `MASViewAttribute` 和 `MASViewConstraint ` 这两个东西，如果我们有一个类来维护这些东西，那就更方便了，于是就有了 [MASConstraintMaker](#MASConstraintMaker-ClassRef)。

	
### <a name="MASConstraintMaker-ClassRef"></a>MASConstraintMaker : NSObject
  
按照我们的想法，上面的几个类已经可以完成我们想要的了，但是问题是，这样依然不能做到简化语法的目的。
  
Masonry 最关键的地方在于这个类，它保存一个主视图 view1，然后针对这个主视图，使用一个 NSArray 来统一管理 MASViewConstraint。
  
这样，我们初始化一个 MASConstraintMaker 类，并赋值一个 view，然后添加其他约束就可以了。因此需要将 view 的基础约束添加成属性来调用：

~~~ Objective-C
  
// MASConstraintMaker.h
  
@property (nonatomic, strong, readonly) MASConstraint *left;
@property (nonatomic, strong, readonly) MASConstraint *top;
@property (nonatomic, strong, readonly) MASConstraint *right;
@property (nonatomic, strong, readonly) MASConstraint *bottom;
@property (nonatomic, strong, readonly) MASConstraint *leading;
@property (nonatomic, strong, readonly) MASConstraint *trailing;
@property (nonatomic, strong, readonly) MASConstraint *width;
@property (nonatomic, strong, readonly) MASConstraint *height;
@property (nonatomic, strong, readonly) MASConstraint *centerX;
@property (nonatomic, strong, readonly) MASConstraint *centerY;
@property (nonatomic, strong, readonly) MASConstraint *baseline;
	
// 这里的 MAS_VIEW 其实就是 UIView，Masonry 自己定义的宏
- (id)initWithView:(MAS_VIEW *)view;
  
~~~
 	
这里我们使用 left 来举例，readonly 是因为这个约束不希望被外部修改，因为 Masonry 特有的链式语法，使用点语法 `view.left` 其实是为了利用 left 的 get 方法，然后创建一个 对应的 MASViewConstraint 并且存到数组中：
 	
~~~ Objective-C
 	
// MASConstraintMaker.m
 	
- (MASConstraint *)left {
	return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeft];
}
	
- (MASConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
	 return [self constraint:nil addConstraintWithLayoutAttribute:layoutAttribute];
}

- (MASConstraint *)constraint:(MASConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
	
	// 创建 MASViewAttribute ，将 NSLayoutAttribute 和 view 绑定起来，
	MASViewAttribute *viewAttribute = [[MASViewAttribute alloc] initWithView:self.view layoutAttribute:layoutAttribute];
	MASViewConstraint *newConstraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
	
	if ([constraint isKindOfClass:MASViewConstraint.class]) {
    	//replace with composite constraint
    	NSArray *children = @[constraint, newConstraint];
    	MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
    	compositeConstraint.delegate = self;
    	[self constraint:constraint shouldBeReplacedWithConstraint:compositeConstraint];
    	return compositeConstraint;
	}
	if (!constraint) {
    	newConstraint.delegate = self;
    	[self.constraints addObject:newConstraint];
	}
	return newConstraint;
}
 	
~~~
  
这个想法是 Masonry 第二精妙之处。我们可以理解为，将 MASConstraintMaker 替换成 view。
  
~~~ Objective-C

MASConstraintMaker *make = [[MASConstraintMaker alloc] initWithView:view1];

make.left.equalTo(superView.mas_top).offset(10).multipliedBy(1.0);
 
~~~
	
以此类推，将 left、right、top、bottom 都添加好以后，调用一个方法，就可以将一个 View 的所有约束都安装好了。

现在看来，已经非常接近我们的目标 `view1.top = superView.top * 1.0 + 10;` 了，不过还是要创建一个 `MASConstraintMaker `，我们也需要想办法简化。
 	
### View+MASAdditions : UIView (MASAdditions)
 
上面的内容中，有一个关键的点，`superView.top` 是从哪里来的？UIView 并没有这样的属性。于是我们需要创建一个 UIView 的分类，给它添加几个属性：
 	
~~~ Objective - C
 	
//  View+MASAdditions.h
 
// 为了不与其他库冲突，添加前缀是一个三方库最基本的操守

@property (nonatomic, strong, readonly) MASViewAttribute *mas_left;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_top;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_right;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottom;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_leading;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_trailing;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_width;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_height;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_centerX;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_centerY;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_baseline;
@property (nonatomic, strong, readonly) MASViewAttribute *(^mas_attribute)(NSLayoutAttribute attr);
 
~~~ 
 
这样，我们就可以调用 `view1.top` 或者 `superView.top` 了。

当然这个类的作用不止于此，程序员都是追求极致简单的。

我们连  MASConstraintMaker 都不希望在使用的时候自己创建，于是需要给 UIView 添加这么一个方法：
 	
~~~ Objective - C
 	
//  View+MASAdditions.h
 	
/**
 *  Creates a MASConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created MASConstraints
 */
 - (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *make))block;
 
~~~
 
这就是我们经常使用的那个方法，为了在给一个 view 添加约束的时候看起来整体性更加强，Masonry 将所有的添加约束方法放在了 block 里面进行，于是就有了如下使用：
 	
~~~ Objective - C
 	
[view1 mas_makeConstraints:^(MASConstraintMaker *make) {
	make.top.equalTo(superview.mas_top).with.offset(10); 
	make.left.equalTo(superview.mas_left).with.offset(10); 
	make.bottom.equalTo(superview.mas_bottom).with.offset(-10); 
	make.right.equalTo(superview.mas_right).with.offset(-10); 
}]; 
 	
~~~
 	
这样，其实很容易就能想到这个 `mas_makeConstraints:^(MASConstraintMaker *make)` 方法是如何实现的：
 	
~~~ Objective - C
 	
- (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *))block {
	self.translatesAutoresizingMaskIntoConstraints = NO;
	MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
	block(constraintMaker);
	return [constraintMaker install];
}
 	
~~~
 	
当然了，系统比较傻，view 的添加约束方法只有添加

~~~ Objective - C
 	
// UIView.h
 	
// UIView (UIConstraintBasedLayoutInstallingConstraints)
 	
- (void)addConstraint:(NSLayoutConstraint *)constraint NS_AVAILABLE_IOS(6_0);
 	
~~~
 	
但是问题是，约束重复叠加是会出问题的。因此 Masonry 提供了两个方法：
 	
~~~ Objective - C
 	
// 更新现有的约束
- (NSArray *)mas_updateConstraints:(void(^)(MASConstraintMaker *make))block;

// 移除旧的约束，并重新添加新的约束
- (NSArray *)mas_remakeConstraints:(void(^)(MASConstraintMaker *make))block;
 	
~~~
 
它们的具体实现也不复杂，其实也就是给 MASConstraintmaker 添加两个布尔值，然后在  `[constraintMaker install]` 的和 `[constraint install]` 的时候根据布尔值来做对应的操作而已。
	
### MASLayoutConstraint : NSLayoutConstraint
	
这个类其实很简单，就是添加了一个属性来做 Debug。其他没有了。
	
~~~ Objective - C
	
@property (nonatomic, strong) id mas_key;
	
~~~
	
**至此，我们回头看看，我们已经完成目标了，其实 Masonry 的最关键的几个类也就在这里了，下面还有一些衍生的。**
	
### NSArray+MASAdditions
	
批量给 view 添加约束，数组里面必须是 UIView 类型的，然后统一给所有 view 添加一致的约束。
	
### NSArray+MASShorthandAdditions
	
龟毛的作者，非要简化一下批量添加约束的方法名....
	
### NSLayoutConstraint+MASDebugAdditions
	
用来做 Debug 用的，这个还是比较有用的，因为官方的 NSLayoutConstraint Debug 跟使用一样恶心。
	
### View+MASShorthandAdditions
	
恩，依然是作者的龟毛，简化一下 View+MASViewAddition 的命名。
	
### ViewController+MASAdditions
	
其实不只是 UIView, UIViewController 也是可以添加约束的。
	
## 总结
	
总的来看，Masonry 有很多可以学习的地方：
	
> 1. 链式语法：脑洞大开的使用方式，让代码使用简单并且易读。这需要非常深厚的编码功底才能想的出来。
2. 巧用分类：使用分类，配合继承和代理，可以简化很多代码，如果说链式语法在实战中使用还是比较麻烦，那么熟练使用分类、继承、协议，将会让你的代码更上一层楼。
3. 思维能力：到现在为止我依然对 Masonry 的作者表示敬佩，非常棒的思维能力，解决了一个大问题。灵活的运用技能会让你在工作的时候事半功倍。

[VFL（Visual Format Language)](http://www.cocoachina.com/ios/20141209/10549.html) 是官方出的简化版，不过真的很难用，而且代码写起来一点都不优雅。

最后，这里还有一篇[解读 Masonry ](http://www.cnblogs.com/ludashi/p/5591572.html)的文章，写的很好，提供了一个类导图，可以让你更加清除整个 Masonry 的结构。
	
