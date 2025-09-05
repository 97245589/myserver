extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

#include <iostream>
#include <list>
#include <sstream>
#include <string>
#include <unordered_map>

using namespace std;
static const char *LLRU_META = "LLRU_META";

struct Lru {
  list<string> ids_;
  unordered_map<string, list<string>::iterator> list_it_;
  int num;

  void update(const string &id, string &evict) {
    if (auto it = list_it_.find(id); it != list_it_.end()) {
      ids_.erase(it->second);
      list_it_.erase(it);
    }
    ids_.push_front(id);
    list_it_[id] = ids_.begin();

    if (list_it_.size() > num) {
      auto it = ids_.rbegin();
      evict = *it;
      list_it_.erase(*it);
      ids_.pop_back();
    }
  }

  void dump() {
    ostringstream oss;
    oss << "num:" << num << endl;
    oss << "itsize:" << list_it_.size() << endl;
    oss << "idssize:" << ids_.size() << endl;
    for (auto id : ids_) {
      oss << id << " ";
    }
    oss << endl;
    cout << oss.str() << endl;
  }
};

struct Llru {
  static int update(lua_State *L);

  static int lru_gc(lua_State *L);
  static void lru_meta(lua_State *L);
  static int create_lru(lua_State *L);
};

int Llru::update(lua_State *L) {
  auto pp = (Lru **)luaL_checkudata(L, 1, LLRU_META);
  auto &lru = **pp;
  size_t len;
  const char *p = luaL_checklstring(L, 2, &len);

  string evict;
  lru.update({p, len}, evict);
  if (evict.size() == 0) return 0;
  lua_pushlstring(L, evict.c_str(), evict.size());
  return 1;
}

int Llru::lru_gc(lua_State *L) {
  auto pp = (Lru **)luaL_checkudata(L, 1, LLRU_META);
  delete *pp;
  return 0;
}

void Llru::lru_meta(lua_State *L) {
  if (luaL_newmetatable(L, LLRU_META)) {
    luaL_Reg l[] = {
        {"update", update},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, lru_gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Llru::create_lru(lua_State *L) {
  int num = luaL_checkinteger(L, 1);
  if (num <= 0) return 0;
  Lru *p = new Lru();
  p->num = num;
  Lru **pp = (Lru **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  lru_meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lutil_lru(lua_State *L) {
  luaL_Reg funcs[] = {{"create_lru", Llru::create_lru}, {NULL, NULL}};

  luaL_newlib(L, funcs);
  return 1;
}
}