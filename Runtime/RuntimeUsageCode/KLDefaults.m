//
//  KLDefaults.m
//
//
//  Created by Kral.Lee on 15/12/23.
//  Copyright © 2015年 Kral.Lee. All rights reserved.
//

#import "KLDefaults.h"
#import <objc/runtime.h>

@interface KLDefaults()

@property (nonatomic, strong) NSMutableDictionary *propertyKeys;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation KLDefaults

#pragma mark - Type Encoding 

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

#pragma mark - Singleton

+ (instancetype)sharedDefaults {
    static dispatch_once_t onceToken;
    static KLDefaults *defaults = nil;
    dispatch_once(&onceToken, ^{
        defaults = [[KLDefaults alloc] init];
    });
    return defaults;
}

#pragma mark - private

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self generateAccessorMethods];
    }
    
    return self;
}

// make propertyName as string
- (NSString *)defaultsKeyForPropertyNamed:(char const *)propertyName {
    NSString *key = [NSString stringWithFormat:@"%s", propertyName];
    return key;
}

- (void)generateAccessorMethods {
    
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    self.propertyKeys = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        
        // set getter selector name
        char *getter = strstr(attributes, ",G");
        if (getter) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        SEL getterSel = sel_registerName(getter);
        free(getter);
        
        // set setter selector name
        char *setter = strstr(attributes, ",S");
        if (setter) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSel = sel_registerName(setter);
        free(setter);
        
        // save selector as key propertyname as value in dictionary
        NSString *key = [self defaultsKeyForPropertyNamed:name];
        [self.propertyKeys setValue:key forKey:NSStringFromSelector(getterSel)];
        [self.propertyKeys setValue:key forKey:NSStringFromSelector(setterSel)];
        
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
        
        char types[5];
        
        snprintf(types, 4, "%c@:", type);
        class_addMethod([self class], getterSel, getterImp, types);
        
        snprintf(types, 5, "v@:%c", type);
        class_addMethod([self class], setterSel, setterImp, types);
    }
    
    free(properties);
}

#pragma mark - IMP for getter & setter

// get propertyName with selector
- (NSString *)defaultsKeyForSelector:(SEL)selector {
    return [self.propertyKeys objectForKey:NSStringFromSelector(selector)];
}

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


@end













