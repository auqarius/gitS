#从发送一个消息（调用一个方法）来说 Runtime
#### 这篇文章其实可以算是我的笔记，因为很多地方和原文章都很像。主要是为了让自己理解，如果你觉得会看不懂，可以建议看看[原文][原文连接]

我们每次调用一个方法，其实就是发送一个消息：

	[receiver message]

在 runtime 中会被转化为: 

	objc_msgSend(receiver, selector)

如果有参数, 例如 
	
	[NSString stringWithFormat:@"a"];
	
会被转换为: 

	objc_msgSend(NSString, @selector("stringWithFormat"), @"a")
	

## objc_msgSend
objc_msgSend 函数的定义如下：

	id objc_msgSend( id self, SEL op, ...);

###  selector SEL

objc_msgSend 函数的第二个参数类型是 SEL

selector 是在 Objective-C 中的方法选择器，用来区分不同的方法，它的数据结构是 SEL :

	typedef struct objc_selector *SEL;
	
其实它就只是一个 C 字符串，用来映射不同的方法。你可以用 Objective-C 的编译器命令 `@selector()` 或者 Runtime 系统的 `sel_registerName` 函数来获得一个 SEL 类型的方法选择器。

*在这里我们可以解释一下为什么 OC 的方法名会那么长。首先不同类中相同的方法所对应的方法选择器是相同的，即是方法名字相同而变量类型不同也会导致它们有相同的方法选择器，所以，我们在写方法命名的时候就需要添加参数类型之类的，最终导致方法名称过长。*

### id
objc_msgSend 第一个参数类型为 id，它是一个指向类实例的指针：

	typedef struct objc_object *id;
	
objc_object 是这样的:

	struct objc_object { Class isa; };
	
objc_object 结构体包含一个 isa 指针，根据 isa 指针就可以找到对象所属的类。但是也不总是能找到，例如 KVO 的实现机制就是将被观察对象的 isa 指针指向一个中间类而不是真实的类。

### Class
从上面我们如何看出来 isa 是一个指针呢，因为 Class 就是一个 objc_class 结构体的指针。

	typedef struct objc_class *Class;
	
而 objc_class 才是我们的重点:
	
	struct objc_class {
		Class isa OBJC_ISA_AVAILABILITY;
		
	#if !__OBJC2__
		Class super_class						OBJC2_UNAVAILABLE; 
		const char *name						OBJC2_UNAVAILABLE;
		long version							OBJC2_UNAVAILABLE;
		long info								OBJC2_UNAVAILABLE;
		long instance_size						OBJC2_UNAVAILABLE;
		struct objc_ivar_list *ivars			OBJC2_UNAVAILABLE;
		struct objc_method_list **methodLists 	OBJC2_UNAVAILABLE;;
		struct objc_cache *cache				OBJC2_UNAVAILABLE;
		struct objc_protocol_list *protocols 	OBJC2_UNAVAILABLE;
	#endif
	
	} OBJC2_UNAVAILABLE;
	
我们可以看到，在运行的时候，一个类关联了它的超类指针，类名，成员变量，方法，缓存，还有附属的协议。
在 objc\_class 结构体中， ivars 是 objc\_ivar\_list 的指针，而 methodLists 是指向 objc\_method\_list 指针的指针，这样就说明我们可以动态的修改 *methodLists 的值来添加成员方法, 这也是 Category 的实现原理，同样也解释了 Category 不能添加属性的原因。当然，你可以用 Runtime 里面的方法来动态的在 Category 中添加 `@dynamic` 属性。

objc\_ivar\_list 和 objc\_method\_list 就不多说了，可以理解为 objc\_ivar / objc\_mehotd 的数组，而 objc\_ivar / objc\_mehotd 后面会说明。

objc_cache 这个是缓存，但是到底是干什么用的，下面会有讲，它很重要。

然后你会发现，Class 里面也有一个 isa 对象，这其实是因为一个 Objective-C 类本身同时也是一个对象。runtime 创建了一种叫做元类(Meta Class)的东西，类的对象所属类型就是元类。类方法就是类对象的实例方法。每个类，只有一个对象，每个类对象也只有一个元类。当你发出一个 `[NSObject alloc]` 的消息时，你其实是发给了 NSObject 的类对象，这个对象呢又是一个元类的实例。而每个元类又有自己的父元类，最终所有的元类都指向根元类为其超类。如下图：

![对象和类对象](http://www.cocos.com/uploads/20141018/1413628797629491.png)
		
Class 的 Root class 是 NSObject ， NSObject 的父类是 nil，说明它没有父类，他的类对象所属的类为 Root meta class。 Root meta class 的父类为 NSObject，其类对象所属的类为自己，而且所有类对象所属的类的类对象为 Root meta class。有点绕，但是不难理解。
		
### Method

Method 代表某一个类中的某一个方法。

	typedef struct objc_method *Method;
	
在这里重要的应该是 objc_method:
	
	struct objc_method {
		SEL method_name					OBJC2_UNAVAILABLE;
		char *method_types				OBJC2_UNAVAILABLE;
		IMP method_imp					OBJC2_UNAVAILABLE;
	}

* 方法名是 SEL 类型，这样我们就能用 selector 来选择方法了。
* method_types 是一个 char 指针，存储这方法的参数类型和返回值类型。
* method_imp 指向了方法的实现，本质上是一个函数指针，后面也会详细说明。

### Ivar

Ivar 用来代表类里面实例变量。
	
	typedef struct objc_ivar *Ivar;
	
	struct objc_ivar {
		char *ivar_name					OBJC2_UNAVAILABLE;
		char *uvar_type					OBJC2_UNAVAILABLE;
		int ivar_offset					OBJC2_UNAVAILABLE;
	#ifdef __LP64_
		int space						OBJC2_UNAVAILABLE;
	#endif
	}									OBJC2_UNAVAILABLE;
		
### IMP

IMP 的定义是：
	
		typedef_id (*IMP)(id, SEL, ...);

它就是一个函数指针这是由编译器根据你的代码生成的。当你发起一个 Objc 消息，最终会执行哪一段代码，都是由这个函数指针指定的。而 IMP 这个函数指针就指向了这个方法的实现。

IMP 指向的方法和 objc_msgSend 函数类型是一样的，参数都包含 id 和 SEL 类型。
*每个方法名对应一个 SEL 类型的方法选择器，而每个实例对象中的 SEL 选择器所对应的方法实现肯定是唯一的，通过一组 id 和 SEL 就能确定唯一的方法实现地址。*

### Cache

Cache 的定义是：
	typedef struct objc_cache *Cache;
	
	struct objc_cache {
		unsigned int mask /* total = mask + 1 */    	OBJC2_UNAVAILABLE;
		unsigned int occupied							OBJC2_UNAVAILABLE;
		Method buckets[1]								OBJC2_UNAVAILABLE;
	};
	
Cache 为方法调用的性能进行优化。首先根据上面的知识我们不难发现，当一个消息被发出的时候，它会在 isa 指向的类的的 method_list 中搜寻可以响应消息的方法, 但是这样效率太低了，一个类不排除有很多个 method，所以，需要一个 cache，当消息被发出的时候，会优先在 Cache 中寻找。每次被调用的方法，都会存储到 Cache 里面。

### Property

`@property` 标记了类中的属性，它是一个指向 objc_property 结构体的指针。
	
	typedef struct objc_property *Property;
	typedef struct objc_property *objc_property_t; // 这个更经常用

可以用过 class_copyPropertyList 和 protocol_copyPropertyList 方法来获取类和协议中的属性

	objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount)
	objc_property_t *protocol_copyPropertyList(Protocol *proto, unsigned int *outCount)
	
返回类型为指向指针的指针，属性列表是一个数组，每个元素的内容都是一个 objc_property_t 指针，而这两个函数返回的值是指向这个数组的指针。

### 使用

在这里有几个比较有用的东西：

* 获取一个类的的类对象（类型为 Class ）:
	
		objc_getClass("NSObject")

* 获取一个属性的名称:
	
		const char *property_getName(objc_property_t property)
	
* 获取一个类的属性和和协议中获取属性:

		objc_property_t class_getProperty(Class cls, const char *name)
		objc_property_t protocol_getProperty(Protocol *proto, const char *name, BOOL isRequiredProperty, BOOL isInstanceProperty)
	
* 获取一个类的属性的名称和类型字符串

		const char *property_getAttributes(objc_property_t property)

在日常 OC 中，我们是无法获取一个类的属性的个数，名字，类型等，但是使用 runtime 我们就可以做到，从而达到某些目的。举个例子：

	@interface Person: NSObject 
	
	@property (nonatomic, copy) NSString *name;
	
	@end
	
我们想要获取它的属性：

	id personClass = objc_getClass("Person")
	unsigned int outCount;
	// 获取属性列表
	objc_property_t *properties = class_copyPropertyList(personClass, &outCount);
	for (int i = 0; i < outCount; i++) {
		// 取出来属性
		objc_property_t property = properties[i];
		// 属性名字
		char propertyName = property_getName(property);
		// 属性的类型
		char propertyAttributes = property_getAttributes(property);
		
		
## Objective-C Associated Objects 

我们可以动态的给一个类添加/获取/删除变量

	void objc_setAssociatedObject ( id object, const void *key, id value, objc_AssociationPolicy policy)
	id objc_getAssociatedObject ( id object, const void *key)
	void objc_removeAssociatedObject ( id object )

这些方法以键值对的形式动态的向对象添加、获取、删除 关联值，其实就是属性。在这里，policy 是一组枚举常量：

	enum {
		OBJC_ASSOCIATION_ASSIGN = 0,
		OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
		OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
		OBJC_ASSOCIATION_RETAIN = 01401,
		OBJC_ASSOCIATION_COPY = 01403
	};

想必也能看出来这对应了 Objective-C 的内存管理的引用计数机制。
		

# 结语

关于 OC Runtime 基础就到此为止了，后面还有消息转发机制和 method swizzling 会再后一篇中记录。
		
		
[原文连接]: http://yulingtianxia.com/blog/2014/11/05/objective-c-runtime/



		