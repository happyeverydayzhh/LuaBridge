//
//  CILuaRuntime.h
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#ifndef __CICore__CILuaRuntime__
#define __CICore__CILuaRuntime__

#include <iostream>
#include "CILuaState.h"

class CILuaRuntime
{
private:
    bool isOpen_;
    lua_State *state_; // lua State Object

    // forbid method aboud sharedInstance
    CILuaRuntime(const CILuaRuntime &);
    CILuaRuntime &operator = (const CILuaRuntime &);
    // Alloc
    CILuaRuntime();
public:
    // Dealloc
    ~CILuaRuntime();
    // instance method
    static CILuaRuntime &instance();
    
    // functions of runtime
    int open();
    void close();
    bool isOpen();
    void loadLibs();
    lua_State* state();
};
#endif /* defined(__CICore__CILuaRuntime__) */
