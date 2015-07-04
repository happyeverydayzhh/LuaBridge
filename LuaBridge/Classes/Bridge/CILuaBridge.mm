//
//  CILuaBridge.mm
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#import "CILuaBridge.h"
#import "CILuaRuntime.h"

@interface ClassInfo : NSObject
@property (nonatomic, strong) NSString *className;
- (instancetype)initWithClassName:(NSString *)className;
@end

@implementation ClassInfo

- (instancetype)initWithClassName:(NSString *)className
{
    self = [super init];
    if (self) {
        _className = className;
    }
    return self;
}
- (void)dealloc
{
//    _className = nil;
//    [super dealloc];
}
@end

@implementation CILuaBridge

CI_OC_DEF_SINGLETON(CILuaBridge);

- (instancetype)init
{
    // Called by singleton.
    self = [super init];
    if (self) {
        _classInfo = [[NSMutableDictionary alloc] init];
        _callbackInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - actions about register, create and binding
- (void)registerClassName:(const char *)className_ luaClassName:(const char *)luaClassName_
{
    // Convert className
    NSString *className = [NSString stringWithUTF8String:className_];
    NSString *luaClassName = [NSString stringWithUTF8String:luaClassName_];
    
    // If it does not exist, return
    if (!className) {
        return;
    }
    if (!luaClassName) {
        return;
    }
    
    // Save className into classInfo
    NSMutableDictionary *classNameDict = _classInfo[luaClassName];
    if (!classNameDict) {
        classNameDict = [NSMutableDictionary dictionary];
        classNameDict[kClassName] = className;
        _classInfo[luaClassName] = classNameDict;
    } else {
        _classInfo[luaClassName][kClassName] = className;
    }
}

/* Register initializer */
- (void)registerInitSelector:(SEL)selector luaClassName:(const char*)luaClassName_ init:(lua_CFunction)init singleton:(BOOL)singleton
{
    // Convert className

    NSString *luaClassName = [NSString stringWithUTF8String:luaClassName_];
    
    // If it does not exist, return
    if (!luaClassName) {
        return;
    }
    
    // Get methodName from SEL type
    const char *methodName_ = sel_getName(selector);
    NSString *methodName = [NSString stringWithUTF8String:methodName_];
    
    // Save methodName into classInfo
    NSMutableDictionary *classNameDict = _classInfo[luaClassName];
    if (classNameDict) {
        classNameDict[kINIT] = methodName;
    } else {
        // Exception
        [NSException raise:NSInvalidArgumentException
                    format:@"classInfo[luaClassName] is nil, please check the function that '- (void)registerClassName: luaClassName:'"];
    }
    
    if (!singleton) {
        CILuaState state = CILuaRuntime::instance().state();
        [self bindingClassFunctions:[[ClassInfo alloc] initWithClassName:luaClassName]];
        state.setGlobal(luaClassName_);
    } else {
        init(CILuaRuntime::instance().state());
    }
}

- (void)registerClassSelector:(SEL)selector functionName:(const char *)functionName_ className:(const char *)className_
{
    // Get className and functionName
    NSString *className = [NSString stringWithUTF8String:className_];
    NSString *functionName = [NSString stringWithUTF8String:functionName_];
    
    // If it does not exist, return.
    if (!className) {
        return;
    }
    if (!functionName) {
        return;
    }
    
    // Get methodName from SEL type, and convert to NSString.
    const char *methodName_ = sel_getName(selector);
    NSString *methodName = [NSString stringWithUTF8String:methodName_];
    
    // Save methodName into classInfo
    NSMutableDictionary *classNameDict = _classInfo[className];
    if (classNameDict) {
        NSMutableDictionary *selectors = classNameDict[kClassSelector];
        if (!selectors) {
            selectors = [NSMutableDictionary dictionary];
            selectors[functionName] = methodName;
            classNameDict[kClassSelector] = selectors;
        } else {
            selectors[functionName] = methodName;
        }
    } else {
        classNameDict[kClassSelector] = @[methodName];
        _classInfo[className] = classNameDict;
    }
}

/* Register member funciton */
- (void)registerSelector:(SEL)selector functionName:(const char *)functionName_ className:(const char *)className_
{
    // Get className and functionName
    NSString *className = [NSString stringWithUTF8String:className_];
    NSString *functionName = [NSString stringWithUTF8String:functionName_];
    
    // If it does not exist, return
    if (!className) {
        return;
    }
    if (!functionName) {
        return;
    }
    
    // Get methodName from SEL type, and convert to NSString.
    const char *methodName_ = sel_getName(selector);
    NSString *methodName = [NSString stringWithUTF8String:methodName_];
    
    // Save methodName into classInfo
    NSMutableDictionary *classNameDict = _classInfo[className];
    if (classNameDict) {
        NSMutableDictionary *selectors = classNameDict[kSelector];
        if (!selectors) {
            selectors = [NSMutableDictionary dictionary];
            selectors[functionName] = methodName;
            classNameDict[kSelector] = selectors;
        } else {
            selectors[functionName] = methodName;
        }
    } else {
        classNameDict[kSelector] = @[methodName];
        _classInfo[className] = classNameDict;
    }
}

- (void)createInstanceWithLuaClassName:(const char *)luaClassName_ state:(lua_State *)L singleton:(BOOL)singleton
{
    CILuaState state = CILuaState(L);
    
    // Convert
    
    NSString *luaClassName = [NSString stringWithUTF8String:luaClassName_];
    NSString *className = _classInfo[luaClassName][kClassName];
    
    // If it does not exist, return
    if (!luaClassName) {
        return;
    }
    if (!className) {
        return;
    }

    // Get init method name from classInfo
    NSString *initMethod = _classInfo[luaClassName][kINIT];
    
    // Get NSClass from string using runtime
    id NSClass = objc_getClass([className UTF8String]);
    // Get SEL type from string using runtime
    SEL initSelector = sel_registerName([initMethod UTF8String]);
    
    // Alloc a new object
    id object = [NSClass alloc];
    
    // End when mode is singleton
    if (singleton) {
        
        // Sending Message,with object,selector and parameter.
        [self objc_msgSendRef:object sel:initSelector parameters:nil];
        
        // Binding self
        [self bindingSelf:object singleton:singleton];
        state.setGlobal(luaClassName_);
        return;
    }
    
    // Get parameters.
    NSArray *callbacks = nil;
    NSArray *parameterObjc = [self dealWithLuaParameters:L callbacks:&callbacks];
    if (callbacks) {
        if (callbacks.count > 0) {
            NSMutableDictionary *callbackDict = _callbackInfo[[object description]];
            if (!callbackDict) {
                callbackDict = [NSMutableDictionary dictionary];
            }
            callbackDict[kINIT] = callbacks;
            _callbackInfo[[object description]] = callbackDict;
        }
    }
    
    // Sending Message,with object,selector and parameter.
    [self objc_msgSendRef:object sel:initSelector parameters:parameterObjc];
    
    // Binding self
    [self bindingSelf:object singleton:singleton];
}

- (void)bindingSelf:(id)obj singleton:(BOOL)singleton
{
    // Get Lua state
    CILuaState state = CILuaRuntime::instance().state();
    
    /* Binding*/
    
    // Step1: push userdata
    state.pushUserdataPtr((__bridge_retained void*)obj);
    
    // Step2: new metaTable
    // This metaTable contains two strings.
    // That are '__index' and '__gc'
    // __index can find the true function.
    // __gc can recycle memory.
    state.newMetaTable(BINDING_OBJECTIVE_C_CLASS);
    state.pushString(INDEX);
    state.pushCFunction(findFunction);
    state.setTable(-3);
    
    if (!singleton) {
        state.pushString(GC);
        state.pushCFunction(gcFunction);
        state.setTable(-3);
    }
    
    // Step3. SetMetaTable
    state.setMetaTable(-2);
}

- (void)bindingClassFunctions:(id)object
{
    // Get Lua state
    lua_State *L = CILuaRuntime::instance().state();
    CILuaState state = L;
    
    state.pushUserdataPtr((__bridge_retained void *)object);
    
    state.newMetaTable(BINDING_CLASS_FUNCTION);
    state.pushString(INDEX);
    state.pushCFunction(findClassFunction);
    state.setTable(-3);
    
    state.setMetaTable(-2);
}

#pragma mark - find and call method
static int gcFunction(lua_State *L)
{
    CILuaState state = CILuaState(L);
    
    // Get userdata which is binding to Lua.
    id object = (__bridge id)state.getUserDataPtr(1);
    
    // unref index of globolIndex
    NSMutableDictionary *callbackInfo = [CILuaBridge sharedInstance].callbackInfo;
    if (!callbackInfo) {
        // TODO
//        [object release];
        return 0;
    }
    
    NSDictionary *functionCallback = callbackInfo[[object description]];
    for (NSString *key in functionCallback.allKeys) {
        NSArray *callbackIds = functionCallback[key];
        for (NSNumber *callbackId in callbackIds) {
            state.unRef(LUA_REGISTRYINDEX, [callbackId intValue]);
        }
    }
    
    [callbackInfo removeObjectForKey:[object description]];
    
    // TODO
//    [object release];

    return 0;
}

/*
 * This function can get functionName.
 * In next step, we should save functionName into metatable in Lua stack.
 * At last, push a LuaCFunction to Lua stack.
 * This LuaCFunction can get all parameters.
 */
static int findClassFunction(lua_State *L)
{
    CILuaState state = CILuaState(L);
    
    // Get methodName
    const char *methodName_ = state.getString(-1);
    
    // Get the metatable
    state.getMetaTable(1);
    if (!state.isType(-1, CI_TABLE)) {
        // If error occur
        state.pushString("Invalid MetaTable.");
        state.error();
    }
    
    // Save methodName into metable
    state.pushString(LUA_INDEX_FUNCTION_NAME);
    state.pushString(methodName_);
    state.set(-3);
    state.pop(1);
    
    // At last, push a CFunction to get parameter.
    state.pushCFunction(sendingClassMessage);
    return 1;
}

/*
 * Called this function, we can get all parameters from Lua stack.
 * Then, deal with parameters using runtime.
 */
static int sendingClassMessage(lua_State *L)
{
    CILuaState state = CILuaState(L);
    
    // Get metatable
    state.getMetaTable(1);
    if (state.isType(-1, CI_NIL)) {
        state.pushString("Not a valid Object.");
        state.error();
    }
    
    // Get function name
    state.pushString(LUA_INDEX_FUNCTION_NAME);
    state.get(-2);
    if (state.isType(-1, CI_NIL)) {
        state.pushString("Not a OO function call.");
        state.error();
    }
    const char * functionName_ = lua_tostring(L, -1);
    NSString *functionName = [NSString stringWithUTF8String:functionName_];
    
    // Get className
    ClassInfo *object = (__bridge ClassInfo *)state.getUserDataPtr(1);
    NSString *luaClassName = object.className;
    NSString *className = [[CILuaBridge sharedInstance] classInfo][luaClassName][kClassName];
    
    // Class Object
    id classObject = (id)objc_getClass([className UTF8String]);
    
    // Pop two elements.
    state.pop(2);
    
    if ([functionName isEqualToString:@"new"]) {
        [[CILuaBridge sharedInstance] createInstanceWithLuaClassName:[luaClassName UTF8String] state:L singleton:NO];
        // Crash when release object
//        [object release];
        return 1;
    }
    
    // Crash when release object
//    [object release];
    
    // Sending message in runtime.
    // Dealing with return values.
    id returnParameter = [[CILuaBridge sharedInstance] sendingMessage:classObject functionName:functionName luaState:L isClassSelector:YES];
    if (!returnParameter) {
        return 0;
    } else {
        [[CILuaBridge sharedInstance] dealWithReturnValue:returnParameter luaState:state];
        return 1;
    }
}

/* 
 * This function can get functionName.
 * In next step, we should save functionName into metatable in Lua stack.
 * At last, push a LuaCFunction to Lua stack.
 * This LuaCFunction can get all parameters.
 */
static int findFunction(lua_State *L)
{
    CILuaState state = CILuaState(L);
    
    // Get methodName
    const char *methodName_ = state.getString(-1);
    
    // Get the metatable
    state.getMetaTable(1);
    
    if (!state.isType(-1, CI_TABLE)) {
        // If error occur
        state.pushString("Invalid MetaTable.");
        state.error();
    }
    
    // Save methodName into metable
    state.pushString(LUA_INDEX_FUNCTION_NAME);
    state.pushString(methodName_);
    state.set(-3);
    state.pop(1);
    
    // At last, push a CFunction to get parameter.
    state.pushCFunction(sendingMessage);
    return 1;
}

/*
 * Called this function, we can get all parameters from Lua stack.
 * Then, deal with parameters using runtime.
 */
static int sendingMessage(lua_State *L)
{
    CILuaState state = CILuaState(L);
    
    // Get metatable
    state.getMetaTable(1);
    if (state.isType(-1, CI_NIL)) {
        state.pushString("Not a valid Object.");
        state.error();
    }
    
    // Get function name
    state.pushString(LUA_INDEX_FUNCTION_NAME);
    state.get(-2);
    if (state.isType(-1, CI_NIL)) {
        state.pushString("Not a OO function call.");
        state.error();
    }
    const char * functionName_ = state.getString(-1);
    NSString *functionName = [NSString stringWithUTF8String:functionName_];
    
    // Get Object
    void *object = state.getUserDataPtr(1);
    
    // Pop two elements.
    state.pop(2);
    
    // Sending message in runtime.
    // Dealing with return values.
    id returnParameter = [[CILuaBridge sharedInstance] sendingMessage:(__bridge id)object functionName:functionName luaState:L isClassSelector:NO];
    if (!returnParameter) {
        return 0;
    } else {
        [[CILuaBridge sharedInstance] dealWithReturnValue:returnParameter luaState:state];
        return 1;
    }
}

#pragma mark - objc_msgSend
- (id)sendingMessage:(id)object functionName:(NSString *)functionName luaState:(lua_State *)L isClassSelector:(BOOL)isClassSelector
{
    // If it does not exist, return nil
    if (!object) {
        return nil;
    }
    if (!functionName) {
        return nil;
    }
    
    // Convert className
    const char *className_ = class_getName([object class]);
    NSString *luaClassName = objc_msgSend(objc_getClass(className_), sel_registerName("luaClassName"));
    
    // Init methodName
    NSString *methodName = nil;
    
    // Get methodName
    // Because function name in Lua is different from method name in ObjectiveC
    NSDictionary *classNameDict = _classInfo[luaClassName];
    if (classNameDict) {
        NSDictionary *selectors;
        if (isClassSelector) {
            selectors = classNameDict[kClassSelector];
        } else {
            selectors = classNameDict[kSelector];
        }
        methodName = selectors[functionName];
    }
    
    // If it does not exist, return nil
    if (!methodName) {
        return nil;
    }
    
    // if the returnType is void, isVoid is YES.
    BOOL isVoid = NO;
    
    // Get Method Type
    // Like that 'respondsToSelector'
    Method method;
    if (!isClassSelector) {
        method = class_getInstanceMethod([(id)object class], sel_registerName([methodName UTF8String]));
        if (!method) {
            // If it does not exist, raised an exception.
            [NSException raise:NSInvalidArgumentException
                        format:@"%@ Method is not found. Please check REGISTER_FUNCTION Macro.", methodName];
        }
    } else {
        method = class_getClassMethod([(id)object class], sel_registerName([methodName UTF8String]));
        if (!method) {
            // If it does not exist, raised an exception.
            [NSException raise:NSInvalidArgumentException
                        format:@"%@ Method is not found. Please check REGISTER_CLASS_FUNCTION Macro.", methodName];
        }
    }

    // Get returnTypeName
    char returnTypeName[256];
    method_getReturnType(method, returnTypeName, 256);
    NSString *returnType = [NSString stringWithUTF8String:returnTypeName];
    if ([returnType isEqualToString:@"v"]) {
        // why returnType is equal to 'v'?
        // 'v' is that "void" first character.
        isVoid = YES;
    }
    
    // Get parameters
    NSArray *callbacks = nil;
    NSArray *parameterObjc = [self dealWithLuaParameters:L callbacks:&callbacks];
    if (callbacks) {
        if (callbacks.count > 0) {
            NSMutableDictionary *callbackDict = _callbackInfo[[object description]];
            if (!callbackDict) {
                callbackDict = [NSMutableDictionary dictionary];
            } else {
                // Unref function index in LUA_REGISTRYINDEX.
                // If not unref, the memery will be leak.
                NSArray *oldCallBacks = callbackDict[functionName];
                for (NSNumber *oldCallBack in oldCallBacks) {
                    CILuaState state = CILuaState(L);
                    state.unRef(LUA_REGISTRYINDEX, [oldCallBack intValue]);
                }
            }
            callbackDict[functionName] = callbacks;
            _callbackInfo[[object description]] = callbackDict;
        }
    }
    
    // msgSend, only have a return value.
    id returnValue =  [self objc_msgSendRef:object sel:sel_registerName([methodName UTF8String]) parameters:parameterObjc];
    
    // @Note
    // If return type is 'void', objc_msgSend funciton will return a dangling pointer.
    // We should use a bool type to manage the return action.
    if (isVoid) {
        return nil;
    } else {
        return returnValue;
    }
}

- (id)objc_msgSendRef:(id)object sel:(SEL)sel parameters:(NSArray *)p
{
    // Using NSInvocation to send message
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:sel];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:object];
    [invocation setSelector:sel];
    
    for (int i=0; i<p.count; i++) {
        id obj = p[i];
        if ([obj isKindOfClass:[NSNumber class]]) {
            const char *numberType = [obj objCType];
            if (0 == strcmp(numberType, @encode(BOOL))) {
                BOOL value = [obj boolValue];
                [invocation setArgument:&value atIndex:i+2];
            } else if (0 == strcmp(numberType, @encode(int))) {
                int value = [obj intValue];
                [invocation setArgument:&value atIndex:i+2];
            } else if (0 == strcmp(numberType, @encode(double))) {
                double value = [obj doubleValue];
                [invocation setArgument:&value atIndex:i+2];
            } else if (0 == strcmp(numberType, @encode(float))) {
                float value = [obj floatValue];
                [invocation setArgument:&value atIndex:i+2];
            }
        } else {
            if ([obj isKindOfClass:[NSString class]]) {
                // Array could not contain nil. Using kNIL instead of nil.
                if ([obj isEqualToString:kNIL]) {
                    obj = nil;
                }
                [invocation setArgument:&obj atIndex:i+2];
            } else {
                [invocation setArgument:&obj atIndex:i+2];
            }
        }
    }
    
    const char* returnType = methodSignature.methodReturnType;
    NSUInteger length = methodSignature.methodReturnLength;

    id result = nil;
    [invocation invoke];
    if (0 == strcmp(returnType, @encode(id))) {
        [invocation getReturnValue:&result];
    } else if (0 == strcmp(returnType, @encode(void))) {
        result = nil;
    } else {
        void *buffer = (void *)malloc(length);
        [invocation getReturnValue:buffer];
        
        if (0 == strcmp(returnType, @encode(BOOL))) {
            result = [NSNumber numberWithBool:*((BOOL*)buffer)];
        } else if (0 == strcmp(returnType, @encode(int))) {
            result = [NSNumber numberWithInt:*((int*)buffer)];
        } else if (0 == strcmp(returnType, @encode(float))) {
            result = [NSNumber numberWithFloat:*((float*)buffer)];
        } else if (0 == strcmp(returnType, @encode(double))) {
            result = [NSNumber numberWithDouble:*((double*)buffer)];
        }
        
        free(buffer);
    }
    
    return result;
}

#pragma mark - deal with parameter in lua stack
- (NSArray *)dealWithLuaParameters:(lua_State *)L callbacks:(NSArray **)callbacks
{
    CILuaState state = CILuaState(L);
    
    NSMutableArray *parameterObjc = [NSMutableArray array];
    
    // Get number of Lua stack
    int parameterNums = state.getTopNum();
    
    if (1 == parameterNums) {
        // Number of parameter is zero.
        return parameterObjc;
    }
    
    for (int i=2; i<=parameterNums; i++) {
        
        // Get type tag.
        int type = state.type(i);
        // Collect all parameters.
        switch (type) {
            case CI_NIL:
                {
                    [parameterObjc addObject:kNIL];
                }
                break;
            case CI_BOOLEAN:
                {
                    bool boolValue = state.getBool(i);
                    if (boolValue) {
                        [parameterObjc addObject:@YES];
                    } else {
                        [parameterObjc addObject:@NO];
                    }
                }
                break;
            case CI_LIGHTUSERDATA:
                {
                    void *userdataValue = state.getUserdata(i);
                    [parameterObjc addObject:(__bridge id)userdataValue];
                }
                break;
            case CI_NUMBER:
                {
                    lua_Number number = (lua_Number)state.getDouble(i);
                    int value1 = (int)number;
                    double value2 = (double)number;
                    if (value1 == value2) {
                        [parameterObjc addObject:@(value1)];
                    } else {
                        [parameterObjc addObject:@(value2)];
                    }
                }
                break;
            case CI_STRING:
                {
                    const char *stringValue = state.getString(i);
                    NSString *string = [NSString stringWithUTF8String:stringValue];
                    [parameterObjc addObject:string];
                }
                break;
            case CI_TABLE:
                {
                    // create two container to fill data
                    id container = [self getObjectWithLuaState:L index:i];
                    [parameterObjc addObject:container];
                }
                break;
            case CI_FUNCTION:
                {
                    // save function index to REGISTRY table
                    if (!*callbacks) {
                        *callbacks = [NSMutableArray array];
                    }
                    
                    int callbackID = state.ref(LUA_REGISTRYINDEX);
                    [parameterObjc addObject:@(callbackID)];
                    [(NSMutableArray *)*callbacks addObject:@(callbackID)];
                }
                break;
            default:
                break;
        }
    }
    return parameterObjc;
}

#pragma mark - deal with returnValue to Lua from Objective C
- (void)dealWithReturnValue:(id)returnParameter luaState:(CILuaState &)state
{
    if ([returnParameter isKindOfClass:[NSString class]]) {
        state.pushString([returnParameter UTF8String]);
        return;
    } else if ([returnParameter isKindOfClass:[NSNumber class]]) {
        const char *objcType = [returnParameter objCType];
        if (0 == strcmp(objcType, @encode(BOOL)) ) {
            state.pushBool([returnParameter boolValue]);
            return;
        } else if (0 == strcmp(objcType, @encode(int))) {
            state.pushInt([returnParameter intValue]);
            return;
        } else if (0 == strcmp(objcType, @encode(double))) {
            state.pushDouble([returnParameter doubleValue]);
            return;
        } else if (0 == strcmp(objcType, @encode(float))) {
            state.pushFloat([returnParameter floatValue]);
            return;
        }
    } else if ([returnParameter isKindOfClass:[NSArray class]]) {
        state.newTable();
        int index = 1;
        for (id object in returnParameter) {
            state.pushInt(index++);
            [self dealWithReturnValue:object luaState:state];
            state.setTable(-3);
        }
        return;
    } else if ([returnParameter isKindOfClass:[NSDictionary class]]) {
        state.newTable();
		for (id key in [returnParameter allKeys]) {
			if ([key isKindOfClass:[NSString class]]
                || [key isKindOfClass:[NSNumber class]]) {
				
				id object = [returnParameter objectForKey:key];
				[self dealWithReturnValue:key luaState:state];
                [self dealWithReturnValue:object luaState:state];
                state.setTable(-3);
			}
		}
        return;
    }
}

#pragma mark - deal with table struct
- (id)getObjectWithLuaState:(lua_State *)L index:(int)index
{
    NSMutableDictionary *tableDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *tableArray = [NSMutableArray array];
    
    CILuaState state = CILuaState(L);
    
    if (state.isType(index, CI_TABLE)) {
        index = state.absIndex(index);
        state.pushNil();
        while (state.next(index)) {
            if (state.isType(-2, CI_STRING)) {
                const char *key_ = state.getString(-2);
                NSString *key = [NSString stringWithUTF8String:key_];
                id value = [self getValueWithLuaState:L];
                if (value) {
                    [tableDictionary setObject:value forKey:key];
                }
                state.pop(1);
            } else if (state.isType(-2, CI_NUMBER)) {
                id value = [self getValueWithLuaState:L];
                if (value) {
                    [tableArray addObject:value];
                }
                state.pop(1);
            }
        }
    }
    
    // return container
    if (tableDictionary.count > 0) {
        return tableDictionary;
    } else if (tableArray.count > 0) {
        return tableArray;
    } else {
        return nil;
    }
}

- (id)getValueWithLuaState:(lua_State *)L
{
    CILuaState state = L;
    if (state.isType(-1, CI_NIL)) {
        return [NSNull null];
    } else if (state.isType(-1, CI_NUMBER)) {
        double doubleValue_ = state.getDouble(-1);
        NSNumber *doubleValue = [NSNumber numberWithDouble:doubleValue_];
        return doubleValue;
    } else if (state.isType(-1, CI_STRING)) {
        const char* stringValue_ = state.getString(-1);
        NSString *stringValue = [NSString stringWithUTF8String:stringValue_];
        return stringValue;
    } else if (state.isType(-1, CI_BOOLEAN)) {
        bool boolValue_ = state.getBool(-1);
        NSNumber *boolValue = [NSNumber numberWithBool:boolValue_];
        return boolValue;
    }
    return nil;
}

#pragma mark - asyn callback
- (void)dealWithAysnCallback:(const char *)functionName object:(id)passingObject selfObject:(id)selfObject
{
    NSString *functionName_ = [NSString stringWithUTF8String:functionName];
    
    if (!passingObject) {
        return;
    }
    
    // Get callbacks dictionary
    NSDictionary *callbacks = _callbackInfo[[selfObject description]];
    if (!callbacks) {
        return;
    }
    
    // Get callbacks of function
    NSArray *functionCallback = callbacks[functionName_];
    if (!functionCallback) {
        return;
    }
    
    // If callbacks is empty, return
    if (functionCallback.count == 0) {
        [NSException raise:NSRangeException format:@"This Lua function have no callback."];
        return;
    }
    
    // If number of callbacks is 1, return
    if (functionCallback.count != 1) {
        [NSException raise:NSRangeException format:@"This function have more than one callback, please call PUSH_TO_LUA_WITH_TAG function."];
        return;
    }
    
    // Only one callbackID
    int callbackID_ = [functionCallback[0] intValue];
    
    CILuaState state = CILuaRuntime::instance().state();
    state.get(callbackID_);
    if (state.isType(-1, CI_FUNCTION)) {
        int returnNumber = 0;
        if ([passingObject isKindOfClass:[NSString class]] ||
            [passingObject isKindOfClass:[NSNumber class]] ||
            [passingObject isKindOfClass:[NSDictionary class]]) {
            returnNumber = 1;
        } else if ([passingObject isKindOfClass:[NSArray class]]) {
            returnNumber = 1;//[(NSArray *)passingObject count];
        }
        [self dealWithReturnValue:passingObject luaState:state];
        int status = state.call(returnNumber, 0);
        if (0 != status) {
            const char* err = state.getString(-1);
            cout<<err<<endl;
        }
    }
}

void PUSH_TO_LUA_WITH_FUNCTION(const char *functionName, id object, id selfObject)
{
    [[CILuaBridge sharedInstance] dealWithAysnCallback:functionName object:object selfObject:selfObject];
}

void PUSH_TO_LUA_WITH_TAG(int callbackId, id object, id selfObject)
{
    // If callbackId is not exist
    NSDictionary *callbackInfo = [CILuaBridge sharedInstance].callbackInfo;
    
    // Get callbacks dictionary
    NSDictionary *callbacks = callbackInfo[[selfObject description]];
    if (!callbacks) {
        return;
    }
    
    BOOL callbackExist = NO;
    for (NSArray *methodCallbacks in callbacks.allValues) {
        for (NSString *callbackIdStr in methodCallbacks) {
            if (callbackId == [callbackIdStr intValue]) {
                callbackExist = YES;
            }
        }
    }
    
    if (!callbackExist) {
        return;
    }
    
    CILuaState state = CILuaRuntime::instance().state();
    state.get(CI_REGISTRYINDEX, callbackId);
    if (state.isType(-1, CI_FUNCTION)) {
        NSUInteger returnNumber = 0;
        if ([object isKindOfClass:[NSString class]] ||
            [object isKindOfClass:[NSNumber class]] ||
            [object isKindOfClass:[NSDictionary class]]) {
            returnNumber = 1;
        } else if ([object isKindOfClass:[NSArray class]]) {
            returnNumber = [(NSArray *)object count];
        }
        [[CILuaBridge sharedInstance] dealWithReturnValue:object luaState:state];
        state.call((int)returnNumber, 0);
    }
}
@end
