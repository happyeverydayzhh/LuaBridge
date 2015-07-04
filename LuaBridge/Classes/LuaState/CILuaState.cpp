//
//  CILuaState.cpp
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#include "CILuaState.h"
#include <sstream>

#pragma mark -
#pragma mark alloc and dealloc
CILuaState::CILuaState()
{
    state_ = NULL;
}

CILuaState::CILuaState(lua_State* state)
{
    state_ = state;
}

CILuaState::~CILuaState()
{
    state_ = NULL;
}

lua_State* CILuaState::luaState(void)
{
    return state_;
}

#pragma mark -
#pragma mark LuaState Load

int CILuaState::loadString(const char *string)
{
    return luaL_loadstring(state_, string);
}

int CILuaState::loadFile(const char *fileName)
{
    return luaL_loadfile(state_, fileName);
}

int CILuaState::doString(const char *string)
{
    return luaL_dostring(state_, string);
}

int CILuaState::doFile(const char *fileName)
{
    return luaL_dofile(state_, fileName);
}

#pragma mark -
#pragma mark LuaState open and new methods
lua_State* CILuaState::newState(void)
{
    return luaL_newstate();
}

void CILuaState::close(void)
{
    lua_close(state_);
}

void CILuaState::openLibs(void)
{
    luaL_openlibs(state_);
}

void CILuaState::openLib(const char *libname, const luaL_Reg *methods)
{
    luaL_openlib(state_, libname, methods, 0);
}

void CILuaState::newTable(void)
{
    lua_newtable(state_);
}

void CILuaState::newMetaTable(const char *value)
{
    luaL_newmetatable(state_, value);
}

void CILuaState::newMultiMetaTable(const char *value)
{
    if (!value)
    {
        return;
    }
    
    // new metatable
    newMetaTable(value);
    
    // set __index meta method
    // ps:__gc,__newindex also belong to meta method.
    setMetaTableIndex();
    
    // get different metatables push into lua state
    getMultiMetaTable(value);
}

#pragma mark -
#pragma mark LuaState set methods
void CILuaState::setTable(int index)
{
    lua_settable(state_, index);
}

void CILuaState::setMetaTable(int index)
{
    lua_setmetatable(state_, index);
}

void CILuaState::setMetaTableIndex(void)
{
    pushString("__index");
    pushValue(-2);
    setTable(-3);
}

void CILuaState::set(int index)
{
    lua_rawset(state_, index);
}

void CILuaState::setGlobal(const char *name)
{
    lua_setglobal(state_, name);
}

#pragma mark -
#pragma mark LuaState is method
bool CILuaState::isType(int index, int type)
{
	return (lua_type(state_, index) == type);
}

#pragma mark -
#pragma mark LuaState push methods
void CILuaState::pushNil(void)
{
    lua_pushnil(state_);
}

void CILuaState::pushBool(bool value)
{
    lua_pushboolean(state_, value ? 1 : 0);
}

void CILuaState::pushString(const char *value)
{
    lua_pushstring(state_, value);
}

void CILuaState::pushValue(int index)
{
    lua_pushvalue(state_, index);
}

void CILuaState::pushDouble(double value)
{
    lua_pushnumber(state_, value);
}

void CILuaState::pushFloat(float value)
{
    lua_pushnumber(state_, value);
}

void CILuaState::pushInt(int value)
{
    lua_pushnumber(state_, value);
}

void CILuaState::pushUint16(unsigned short value)
{
    lua_pushnumber(state_, value);
}

void CILuaState::pushUint32(unsigned int value)
{
    lua_pushnumber(state_, value);
}

void CILuaState::pushUint64(unsigned long long value)
{
    lua_pushnumber(state_, value);
}

void** CILuaState::pushUserdataPtr(void *ptr)
{
    void **p = (void**)lua_newuserdata(state_, sizeof(void*));
	*p = ptr;
    
    return p;
}

void CILuaState::pushLightUserdata(void *value)
{
    lua_pushlightuserdata(state_, value);
}

void CILuaState::pushCFunction(lua_CFunction value)
{
    lua_pushcfunction(state_, value);
}

#pragma mark -
#pragma mark LuaState get methods
bool CILuaState::getBool(int index)
{
    if (isType(index, CI_BOOLEAN))
    {
		return (lua_toboolean(state_,index));
	}
    return false;
}

const char * CILuaState::getString(int index)
{
    if (isType(index, CI_STRING))
    {
        return (lua_tostring(state_, index));
    }
    return NULL;
}

double CILuaState::getDouble(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (double)(lua_tonumber(state_, index));
    }
    return 0;
}

float CILuaState::getFloat(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (float)(lua_tonumber(state_, index));
    }
    return 0;
}

int CILuaState::getInt(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (int)(lua_tonumber(state_, index));
    }
    return 0;
}

unsigned short CILuaState::getUint16(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (unsigned short)(lua_tonumber(state_, index));
    }
    return 0;
}

unsigned int CILuaState::getUint32(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (unsigned int)(lua_tonumber(state_, index));
    }
    return 0;
}

unsigned long long CILuaState::getUint64(int index)
{
    if (isType(index, CI_NUMBER))
    {
        return (unsigned long long)(lua_tonumber(state_, index));
    }
    return 0;
}

void* CILuaState::getUserdata(int index)
{
    if (isType(index, CI_LIGHTUSERDATA) ||
        isType(index, CI_USERDATA))
    {
        return (void *)(lua_touserdata(state_, index));
    }
    return NULL;
}

void* CILuaState::getUserDataPtr(int index)
{
    void *p = 0;
    
    if (isType(index, CI_USERDATA))
    {
        p = *(void **)lua_touserdata(state_, index);
    }
    
    return p;
}

void CILuaState::getTable(int index)
{
    lua_gettable(state_, index);
}

void CILuaState::getMetaTable(const char *value)
{
    luaL_getmetatable(state_, value);
}

void CILuaState::getMetaTable(int index)
{
    lua_getmetatable(state_, index);
}

void CILuaState::getMultiMetaTable(const char *value)
{
    if (!value)
    {
        return;
    }
    
    string metaTableNames(value);
    string::size_type index;
    int count = 0;
    
    // do while to get each metaTableName.
    // if metaTableName is existed, getMetaTable with name.
    while (index != string::npos)
    {
        index = metaTableNames.find('_');
        
        if (index != string::npos)
        {
            string name = metaTableNames.substr(0, index);
            getMetaTable(name.c_str());
            count++;
            metaTableNames = metaTableNames.substr(index + 1);
        }
        else
        {
            // if not found, only have a key or the last key
            getMetaTable(metaTableNames.c_str());
            count++;
        }
        
    }

    // ex:if we need 4 metaTables, we should setMetaTable 4 times.
    // @note that, there is a counter above statements.
    for (int i=0; i<count; i++)
    {
        setMetaTable(-2);
    }

}

void CILuaState::get(int index)
{
    lua_rawget(state_, index);
}

void CILuaState::get(int tableIndex, int searchIndex)
{
    lua_rawgeti(state_, tableIndex, searchIndex);
}

int CILuaState::getTopNum()
{
    return lua_gettop(state_);
}

void CILuaState::getGlobal(const char *name)
{
    lua_getglobal(state_, name);
}

size_t CILuaState::getObjLength(int index)
{
    return lua_objlen(state_, index);
}

#pragma mark - LuaState Coroutine
int CILuaState::resume(int nResult)
{
    return lua_resume(state_, nResult);
}

int CILuaState::yield(int nResult)
{
    return lua_yield(state_, nResult);
}

#pragma mark - others
void CILuaState::pop(int num)
{
    lua_pop(state_, num);
}

void CILuaState::error()
{
    lua_error(state_);
}

int CILuaState::next(int index)
{
    return lua_next(state_, index);
}

int CILuaState::call(int nargs, int nresults)
{
    return lua_pcall(state_, nargs, nresults, 0);
}

int CILuaState::ref(int tableIndex)
{
    return luaL_ref(state_, tableIndex);
}

void CILuaState::unRef(int tableIndex, int Id)
{
    luaL_unref(state_, tableIndex, Id);
}

int CILuaState::type(int index)
{
    return lua_type(state_, index);
}

int CILuaState::absIndex(int index)
{
    if (index < 0) {
        return lua_gettop(state_) + index + 1;
    }
    return index;
}

void CILuaState::checkParams(const char* params, CIError &error)
{
    for (int i=0; params[i]; ++i)
    {
        int type = CI_NIL;
        
        type = this->type(i+1);
        
        // Nil type is a right value.
        if (type == CI_NIL)
        {
            continue;
        }
        
        switch (params[i]) {
                // Number
            case 'N':
                if (type != CI_NUMBER)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_NUMBER.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // Boolean
            case 'B':
                if (type != CI_BOOLEAN)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_BOOLEAN.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // String
            case 'S':
                if (type != CI_STRING)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_STRING.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // Table
            case 'T':
                if (type != CI_TABLE)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_TABLE.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // Function
            case 'F':
                if (type != CI_FUNCTION)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_FUNCTION.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // Light userdata
            case 'L':
                if (type != CI_LIGHTUSERDATA)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_LIGHTUSERDATA.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("Please check the parameter.");
                }
                break;
                // Userdata
            case 'U':
                if (type != CI_USERDATA)
                {
                    std::ostringstream stringStream;
                    stringStream << "The type of parameter " << i+1 << " is not CI_USERDATA.";
                    std::string failureReason = stringStream.str();
                    
                    error.setError();
                    error.setFailureReason(failureReason);
                    error.setSuggestion("The type of parameter11");
                }
                break;
                // Any type
            case '*':
                break;
        }
    }
}