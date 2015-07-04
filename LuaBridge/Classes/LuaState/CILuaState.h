//
//  CILuaState.h
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#ifndef __libCICore__CILuaState__
#define __libCICore__CILuaState__

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

#include <iostream>
#include <string>
#include "CIError.h"

#define CI_NIL           LUA_TNIL
#define CI_BOOLEAN       LUA_TBOOLEAN
#define CI_LIGHTUSERDATA LUA_TLIGHTUSERDATA
#define CI_NUMBER        LUA_TNUMBER
#define CI_STRING        LUA_TSTRING
#define CI_TABLE         LUA_TTABLE
#define CI_FUNCTION      LUA_TFUNCTION
#define CI_USERDATA      LUA_TUSERDATA
#define CI_THREAD        LUA_TTHREAD

#define CI_REGISTRYINDEX LUA_REGISTRYINDEX
#define CI_ENVIRONINDEX  LUA_ENVIRONINDEX
#define CI_GLOBALSINDEX  LUA_GLOBALSINDEX

using namespace std;
class CILuaState
{
private:
    lua_State *state_;
    CILuaState();
public:
    
    // alloc and dealloc
    CILuaState(lua_State* state);
    ~CILuaState();
    
    // lua_State ,type lua_State *
    lua_State* luaState(void);
    
    // Load
    int loadString(const char *string);
    int loadFile(const char *fileName);
    int doString(const char *string);
    int doFile(const char *fileName);
    
    // LuaState open and New methods
    static lua_State* newState(void);
    void close(void);
    void openLibs(void);
    void openLib(const char *libname, const luaL_Reg *methods);
    
    void newTable(void);
    void newMetaTable(const char *value);
    void newMultiMetaTable(const char *value);
    
    // LuaState set methods
    void setTable(int index);
    void setMetaTable(int index);
    void setMetaTableIndex(void);
    void set(int index);
    void setGlobal(const char *name);
    
    // LuaState is method
    bool isType(int index, int type);
    
    // LuaState push methods
    void pushNil(void);
    void pushBool(bool value);
    void pushString(const char *value);
    void pushValue(int index);
    void pushDouble(double value);
    void pushFloat(float value);
    void pushInt(int value);
    void pushUint16(unsigned short value);
    void pushUint32(unsigned int value);
    void pushUint64(unsigned long long value);
    void** pushUserdataPtr(void *ptr);
    void pushLightUserdata(void *value);
    void pushCFunction(lua_CFunction value);
    
    // LuaState get methods
    bool getBool(int index);
    const char* getString(int index);
    double getDouble(int index);
    float getFloat(int index);
    int getInt(int index);
    unsigned short getUint16(int index);
    unsigned int getUint32(int index);
    unsigned long long getUint64(int index);
    void* getUserdata(int index);
    void* getUserDataPtr(int index);
    void getTable(int index);
    void getMetaTable(const char *value);
    void getMetaTable(int index);
    void getMultiMetaTable(const char *value);
    void get(int index);
    void get(int tableIndex, int searchIndex);
    int getTopNum();
    void getGlobal(const char *name);
    size_t getObjLength(int index);
    
    // Coroutine
    int resume(int nResult);
    int yield(int nResult);
    
    // others
    void pop(int num);
    void error();
    int next(int index);
    int call(int nargs, int nresults);
    int ref(int tableIndex);
    void unRef(int tableIndex, int Id);
    int type(int index);
    int absIndex(int index);
    void checkParams(const char* params, CIError &error);
};


#endif /* defined(__libCICore__CILuaState__) */
