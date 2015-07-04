//
//  CILuaFooFactory.m
//  LuaBridgeDemo
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#import "CILuaFooFactory.h"

@implementation CILuaFooFactory

DEF_LUA_CLASS_FACTORY("CIFoo",CILuaFooFactory)
{
    REGISTER_INIT_FACTORY(@selector(initWithFoo:))
    REGISTER_CLASS_FUNCTION("fooClass", @selector(fooClass))
    REGISTER_FUNCTION("setValue", @selector(setValue:))
    REGISTER_FUNCTION("value", @selector(value))
}

+ (void)fooClass
{
    NSLog(@"CIFoo fooClass is called.");
}

- (instancetype)initWithFoo:(int)value
{
    self = [super init];
    if (self) {
        _foo = [[CIFoo alloc] init];
        _foo.value = value;
    }
    return self;
}

- (void)setValue:(int)value
{
    _foo.value = value;
}

- (int)value
{
    return _foo.value;
}

@end
