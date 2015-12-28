# Runtime 使用实例

学习了那么多关于 Runtime 的知识，但是如果不会用还是徒劳，这里记录下我在项目中学到的两种用法，这都是我的同事写的，最开始我都看不懂，现在至少能明白是在干什么了。

## 空的 backButtonItemTitle

系统的 UINavigationController 会自动在子 ViewController 的 navigationBar 左上角添加返回按钮，跟广大设计湿的审美不同，苹果让这个返回按钮的标题显示为上一层视图的标题，而通常的习惯是`返回`或者空，于是苦逼的程序员就开始一个页面一个页面的重复写。使用继承也是一个不错的选择，不过还是得多继承好几个，在这里我们用 Method swizzled 来完成这个需求会比较好一点。

首先我们需要创建一个 UIViewController 的 Category。名字就叫 UIViewController+CustomBackButtom。
.h 中不需要写任何代码，只看 .m。

	#import "UIViewController+ CustomBackButtom"
	#import <objc/runtime.h>

	@implementation UIViewController (CustomBackButtom)

	+(void)load {
	    static dispatch_once_t onceToken;
	    dispatch_once(&onceToken, ^{
	        Class class = [self class];
        
        SEL originalSelecor = @selector(viewDidLoad);
        SEL swizzledSelector = @selector(emptyBack_viewDidLoad);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelecor);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL methodAdded = class_addMethod(class, originalSelecor, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (methodAdded) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
	}


	- (void)emptyBack_viewDidLoad {
	    [self emptyBack_viewDidLoad];
	    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
	    [self.navigationItem setBackBarButtonItem:backButtonItem];
	}

这个例子不需要多说什么，还是比较简单的。

## 存入 UserDefaults 类

这是一个比较厉害的想法了：平常我们写代码的时候，会使用  NSUserDefaults 存入和取出一些东西，其实代码也不多，就那么几行，不过程序员的风范就是，能少则少。所以，**如果我们能写一个类，然后只需要设定属性，然后就像很简单的存取属性一样就能完成本地存储**，那该多嗨皮。这里就是这么做了。这个想法的源头是 github 上面的一个开源工具 [GVUserDefaults](https://github.com/gangverk/GVUserDefaults)，而这个想法，是在这个工具的基础上，进行了更加深度的一步优化，让使用更加简单。

先说说思路：

1. 每一个类的属性都会有 setter 和 getter 方法，`@dynamic`关键字可以允许程序员来写 setter 和 getter 方法。那么在 setter 和 getter 方法中做 NSUserDefaults 的存取操作的话就能达到我们的需求。
2. 取出每个属性的名称和类型，把每种类型对应的存取方法都写一遍，然后根据属性的类型选择方法并获取到这个方法的 IMP，然后自己创建一个 SEL ，这样就可以使用 `OBJC_EXPORT BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types)` 来为属性来添加 setter 和 getter 方法。
3. 每一个属性在保存的时候，userdefaults 是需要一个 key 的，在这里，将属性的名字当做 key，存入 userdefaults。在这里生成一个 NSDictionary,将 userdefaults 所要使用的 key 当做这个字典的 value，将方法的 SEL 当做字典的 key，存入字典。这样再方法调用的时候只需要使用 _cmd 就可以获取当然方法的 SEL 了。

创建一个类，叫做 XXDefaults ，在项目中，这样的存取，最方便和容易的是使用单例了。所以我们先写出来单例模式。这就不贴代码了。

然后在 .m 中写好两个私有属性：

	@property (nonatomic, strong) NSMutableDictionary *propertyKeys;

	@property (nonatomic, strong) NSUserDefaults *userDefaults;
	
对了，可别忘了 `#import <objc/runtime.h>`，还记得 [Type Encoding](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html) 么？我们要先把它都写成枚举。就是为了后面我们区分参数的类型，这个也是 class_addMethod 中的一个重要参数。

	enum TypeEncodings {
	    Char                = 'c',
	    Bool                = 'B',
	    Short               = 's',
	    Int                 = 'i',
	    Long                = 'l',
	    LongLong            = 'q',
	    UnsignedChar        = 'C',
	    UnsignedShort       = 'S',
	    UnsignedInt         = 'I',
	    UnsignedLong        = 'L',
	    UnsignedLongLong    = 'Q',
	    Float               = 'f',
	    Double              = 'd',
	    Object              = '@'
	};

我们最重要的内容应该是，获取 SEL，获取 IMP，在这之前，我们先把所有类型对应的 IMP 都先写出来，有几个类型是可以通用的，所以方法不会太多：
	
	
	#pragma mark - IMP for getter & setter

	// long long value getter & setter
	static long long longLongGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return [[self.userDefaults objectForKey:key] longLongValue];
	}

	static void longLongSetter(KLDefaults *self, SEL _cmd, long long value) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    NSNumber *object = [NSNumber numberWithLongLong:value];
	    [self.userDefaults setObject:object forKey:key];
	    [self.userDefaults synchronize];
	}

	// bool value getter & setter
	static bool boolGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return [self.userDefaults boolForKey:key];
	}

	static void boolSetter(KLDefaults *self, SEL _cmd, bool value) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    [self.userDefaults setBool:value forKey:key];
	    [self.userDefaults synchronize];
	}

	// integer value getter & setter
	static int integerGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return (int)[self.userDefaults integerForKey:key];
	}

	static void integerSetter(KLDefaults *self, SEL _cmd, int value) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    [self.userDefaults setInteger:value forKey:key];
	    [self.userDefaults synchronize];
	}

	// float value getter & setter
	static float floatGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return [self.userDefaults floatForKey:key];
	}

	static void floatSetter(KLDefaults *self, SEL _cmd, float value) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    [self.userDefaults setFloat:value forKey:key];
	    [self.userDefaults synchronize];
	}

	// double value getter & setter
	static double doubleGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return [self.userDefaults doubleForKey:key];
	}

	static void doubleSetter(KLDefaults *self, SEL _cmd, double value) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    [self.userDefaults setDouble:value forKey:key];
	    [self.userDefaults synchronize];
	}

	// object value getter * setter
	static id objectGetter(KLDefaults *self, SEL _cmd) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    return [self.userDefaults objectForKey:key];
	}

	static void objectSetter(KLDefaults *self, SEL _cmd, id object) {
	    NSString *key = [self defaultsKeyForSelector:_cmd];
	    if (object) {
	        [self.userDefaults setObject:object forKey:key];
	    } else {
	        [self.userDefaults removeObjectForKey:key];
	    }
	    [self.userDefaults synchronize];
	}

这段代码中使用到的方法 `defalutsKeyForSelector:` , 通过 SEL 找到我们 userdefaults 要使用的 key：

	// 每一个属性在保存的时候，userdefaults 是需要一个 key 的，在这里，将属性的名字当做 key，存入 userdefaults。 
	// 在这里生成一个 NSDictionary,将 userdefaults 所要使用的 key 当做这个字典的 value，将方法的 SEL 当做字典的 key，存入字典。
	// 这样再方法调用的时候只需要使用 _cmd 就可以获取当然方法的 SEL 了。
	
	// get propertyName with selector
	- (NSString *)defaultsKeyForSelector:(SEL)selector {
	    return [self.propertyKeys objectForKey:NSStringFromSelector(selector)];
	}
	
下面就是最重要的部分，获取 SEL 和 IMP。

* 获取所有属性内容

		unsigned int count = 0;
   		objc_property_t *properties = class_copyPropertyList([self class], &count);
       	
* 单个属性及属性的名字和类型, 在 for 循环内

   		objc_property_t property = properties[i];
   		const char *name = property_getName(property);
      	const char *attributes = property_getAttributes(property);
      	
* 获取 getter SEL，在这里其实就是字符串的操作，[strstr]、[strdup]、[strsep] 是 C++ 的语法。而这个 `,G` 是为了看看是不是有用户自定义过getter 方法，具体原因请看[这里][1]。
 
      	char *getter = strstr(attributes, ",G");
        if (getter) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        SEL getterSel = sel_registerName(getter);
        free(getter);
  
* 获取 setter SEL，同样也是字符串操作，[asprintf]、[toupper] 是 C 的语法。
  		
  		char *setter = strstr(attributes, ",S");
        if (setter) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSel = sel_registerName(setter);
        free(setter);
  
* 然后我们要将属性名和属性的 setter、getter 方法联系起来：

		NSString *key = [self defaultsKeyForPropertyNamed:name];
		[self.propertyKeys setValue:key forKey:NSStringFromSelector(getterSel)];
		[self.propertyKeys setValue:key forKey:NSStringFromSelector(setterSel)];
  
* 下面就是 IMP 和 type 了: 
	
		// IMP for setter & getter
		IMP getterImp = NULL;
		IMP setterImp = NULL;
		// type
		char type = attributes[1];
		switch (type) {
		  case Short:
		  case Long:
		  case LongLong:
		  case UnsignedChar:
		  case UnsignedShort:
		  case UnsignedInt:
		  case UnsignedLong:
		  case UnsignedLongLong:
		      getterImp = (IMP)longLongGetter;
		      setterImp = (IMP)longLongSetter;
		      break;
		      
		  case Bool:
		  case Char:
		      getterImp = (IMP)boolGetter;
		      setterImp = (IMP)boolSetter;
		      break;
		      
		  case Int:
		      getterImp = (IMP)integerGetter;
		      setterImp = (IMP)integerSetter;
		      break;
		      
		  case Float:
		      getterImp = (IMP)floatGetter;
		      setterImp = (IMP)floatSetter;
		      break;
		      
		  case Double:
		      getterImp = (IMP)doubleGetter;
		      setterImp = (IMP)doubleSetter;
		      break;
		      
		  case Object:
		      getterImp = (IMP)objectGetter;
		      setterImp = (IMP)objectSetter;
		      break;
		      
		  default:
		      free(properties);
		      [NSException raise:NSInternalInconsistencyException format:@"Unsupported type of property \"%s\" in class %@", name, self];
		      break;
		}
  
* 有了 SEL 、 IMP、再需要 type 就可以添加 setter、getter 方法了，当然这里 type 是使用 type encodeing 的：

		char types[5];
		        
		snprintf(types, 4, "%c@:", type);
		class_addMethod([self class], getterSel, getterImp, types);
		   
		snprintf(types, 5, "v@:%c", type);
		class_addMethod([self class], setterSel, setterImp, types);
 
 
 以上就是了
  
  
[strstr]:	http://baike.baidu.com/view/745156.htm
[strdup]: http://baike.baidu.com/view/1028541.htm
[strsep]: http://baike.baidu.com/view/2466295.htm
[1]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW1
[asprintf]: http://baike.baidu.com/view/8507235.htm
[toupper]: http://baike.baidu.com/view/1081141.htm