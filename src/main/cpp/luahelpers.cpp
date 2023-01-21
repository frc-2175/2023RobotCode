#include <cstdio>
#include <cstring>
#include <string>

#include "luahelpers.h"

const char* luaSearchPaths[] = {
  "/home/lvuser/lua/",
  ".\\src\\lua\\",
  "./src/lua/"
};

int RunLuaFile(lua_State* L, const char* filename) {
  int fileFindError = 0;
  for (auto searchpath : luaSearchPaths) {
    char filenamebuf[1024];
    sprintf(filenamebuf, "%s%s", searchpath, filename);
    printf("Trying to load file %s...\n", filenamebuf);

    fileFindError = luaL_loadfile(L, filenamebuf);
    if (fileFindError) {
      printf("Failed to load file %s: %s\n", filename, lua_tostring(L, -1));
    } else {
      break;
    }
  }

  if (fileFindError) {
    return fileFindError;
  }

  int result = lua_pcall(L, 0, LUA_MULTRET, 0);
  if (result) {
    printf("Failed to run %s: %s\n", filename, lua_tostring(L, -1));
  }
  return result;
}

int RunLuaString(lua_State* L, const char* str) {
  int result = luaL_dostring(L, str);
  if (result) {
    printf("Failed to run script: %s\n", lua_tostring(L, -1));
  }
  return result;
}

char* stdStringForLua(std::string str) {
  char* cstr = new char[str.length() + 1];
  std::strcpy(cstr, str.c_str());
  return cstr;
}