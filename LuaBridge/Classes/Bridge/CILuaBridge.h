//
//  CILuaBridge.h
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CILuaState.h"
#import "CIMacro_iOS.h"
#import <objc/message.h>
#import <objc/runtime.h>

#define DEF_LUA_CLASS_FACTORY(__luaClassName, __className) \
    static int init(lua_State *L) \
    { \
        [[CILuaBridge sharedInstance] createInstanceWithLuaClassName:__luaClassName state:L singleton:NO]; \
        return 1; \
    } \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)initialize \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)loadMetaTable

#define DEF_LUA_CLASS_SINGLETON(__luaClassName, __className) \
    static int init(lua_State *L) \
    { \
        [[CILuaBridge sharedInstance] createInstanceWithLuaClassName:__luaClassName state:L singleton:YES]; \
        return 1; \
    } \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)load \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)loadMetaTable

#define DEF_LUA_CLASS_LIBRARY(__luaClassName, __className) \
    static int init(lua_State *L) \
    { \
        [[CILuaBridge sharedInstance] createInstanceWithLuaClassName:__luaClassName state:L singleton:NO]; \
        return 1; \
    } \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)load \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)initialize \
    { \
        [[CILuaBridge sharedInstance] registerInitSelector:@selector(init) luaClassName:__luaClassName init:init singleton:NO]; \
    } \
    + (void)loadMetaTable

#define DEF_LUA_CLASS_FACTORY_EXT(__luaClassName, __className) \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)initialize \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)loadMetaTable

#undef  DEF_LUA_CLASS_SINGLETON_EXT
#define DEF_LUA_CLASS_SINGLETON_EXT(__luaClassName, __className) \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)load \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)initialize \
    { \
        struct objc_super mySuper = { \
            .receiver = self, \
            .super_class = class_getSuperclass(object_getClass(self)) \
        }; \
        objc_msgSendSuper(&mySuper, sel_registerName("loadMetaTable")); \
    } \
    + (void)loadMetaTable

#define DEF_LUA_CLASS_LIBRARY_EXT(__luaClassName, __className) \
    static const char* luaClassName() \
    { \
        return __luaClassName; \
    } \
    + (NSString *)luaClassName \
    { \
        return [NSString stringWithUTF8String:__luaClassName]; \
    } \
    + (void)load \
    { \
        [[CILuaBridge sharedInstance] registerClassName:#__className luaClassName:__luaClassName]; \
    } \
    + (void)initialize \
    { \
        struct objc_super mySuper = { \
            .receiver = self, \
            .super_class = class_getSuperclass(object_getClass(self)) \
        }; \
        objc_msgSendSuper(&mySuper, sel_registerName("loadMetaTable")); \
    } \
    + (void)loadMetaTable

#define CI_LUA_OC_REGISTER(__ClassName__) \
    objc_msgSend((id)objc_getClass(#__ClassName__), sel_registerName("loadMetaTable"));

#define REGISTER_INIT_FACTORY(__selector) \
    [[CILuaBridge sharedInstance] registerInitSelector:__selector luaClassName:luaClassName() init:init singleton:NO];

#define REGISTER_INIT_SINGLETON(__selector) \
    [[CILuaBridge sharedInstance] registerInitSelector:__selector luaClassName:luaClassName() init:init singleton:YES];

#define REGISTER_CLASS_FUNCTION(__name, __selector) \
    [[CILuaBridge sharedInstance] registerClassSelector:__selector functionName:__name className:luaClassName()];

#define REGISTER_FUNCTION(__name, __selector) \
    [[CILuaBridge sharedInstance] registerSelector:__selector functionName:__name className:luaClassName()];

static const char *LUA_INDEX_FUNCTION_NAME   = "__luaFunctionName";
static const char *BINDING_CLASS_FUNCTION    = "__bindingClassFunctions";
static const char *BINDING_OBJECTIVE_C_CLASS = "__bindingObjcClass";
static const char *INDEX                     = "__index";
static const char *GC                        = "__gc";
static const char *METATABLE                 = "__metatable";
static const NSString *kINIT                 = @"__kInit";
static const NSString *kSelector             = @"__kSelector";
static const NSString *kClassSelector        = @"__kClassSelector";
static const NSString *kCallBack             = @"__kCallback";
static const NSString *kClassName            = @"__kClassname";
static const NSString *kFunctionName         = @"__kFunctionName";
static       NSString *kNIL                  = @"__k_CI_NIL_IN_LUA";

@interface CILuaBridge : NSObject
CI_OC_AS_SINGLETON(CILuaBridge)

@property (nonatomic, strong) NSMutableDictionary *classInfo;
@property (nonatomic, strong) NSMutableDictionary *callbackInfo;

- (void)registerClassName:(const char *)className_
             luaClassName:(const char *)luaClassName_;

- (void)registerInitSelector:(SEL)selector
                luaClassName:(const char*)luaClassName_
                        init:(lua_CFunction)init
                   singleton:(BOOL)singleton;

- (void)registerClassSelector:(SEL)selector
                 functionName:(const char *)functionName_
                    className:(const char *)className_;

- (void)registerSelector:(SEL)selector
            functionName:(const char *)functionName_
               className:(const char *)className_;

- (void)createInstanceWithLuaClassName:(const char *)luaClassName_
                                 state:(lua_State *)L
                             singleton:(BOOL)singleton;

- (void)dealWithAysnCallback:(const char *)functionName
                      object:(id)passingObject
                  selfObject:(id)selfObject;

// C interface
void PUSH_TO_LUA_WITH_FUNCTION(const char *functionName, id object, id selfObject);
void PUSH_TO_LUA_WITH_TAG(int callbackId, id object, id selfObject);
@end
