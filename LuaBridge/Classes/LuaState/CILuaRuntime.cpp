//
//  CILuaRuntime.cpp
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#include "CILuaRuntime.h"
#include "assert.h"

CILuaRuntime::CILuaRuntime()
{
    state_ = NULL;
}

CILuaRuntime::~CILuaRuntime()
{
    close();
    isOpen_ = false;
    state_ = NULL;
}

CILuaRuntime &CILuaRuntime::instance()
{
    static CILuaRuntime CI_LUA_RUNTIME;
    return CI_LUA_RUNTIME;
}

int CILuaRuntime::open()
{
    if (isOpen_)
    {
        return 0;
    }
    
    // new state
    state_ = CILuaState::newState();
    
    if (state_)
    {
        isOpen_ = true;
    }
    
    return 0;
}

void CILuaRuntime::close()
{
    // close lua_state
    CILuaState state = state_;
    state.close();
    
    state_ = NULL;
    
    if (!state_)
    {
        isOpen_ = false;
    }
}

bool CILuaRuntime::isOpen()
{
    // return status
    return isOpen_;
}

void CILuaRuntime::loadLibs()
{
    // open base lua library
    CILuaState state = state_;
    state.openLibs();
}

lua_State* CILuaRuntime::state()
{
    if (!isOpen_) {
        assert(state_);
    }
    return state_;
}
