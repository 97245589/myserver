extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

#include <iostream>
using namespace std;

#include "rank.hpp"

static const char *LRANK_META = "LRANK_META";

struct Lrank {
  static int create_lrank(lua_State *L);
  static void lrank_meta(lua_State *L);
  static int lrank_gc(lua_State *L);

  static int add(lua_State *L);
  static int dump(lua_State *L);
  static int arr_info(lua_State *L);
};

int Lrank::arr_info(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  auto &rank = **pp;
  int num = lua_tointeger(L, 2);
  if (num == 0) {
    num = rank.max_num_;
  }
  auto &ranks = rank.ranks_;
  if (ranks.size() == 0) return 0;

  int c = 0;
  lua_createtable(L, num * 3, 0);
  for (auto &&data : ranks) {
    lua_pushlstring(L, data.uid_.c_str(), data.uid_.size());
    lua_rawseti(L, -2, ++c);
    lua_pushinteger(L, data.score_);
    lua_rawseti(L, -2, ++c);
    lua_pushinteger(L, data.time_);
    lua_rawseti(L, -2, ++c);
    if (c >= 3 * num) {
      break;
    }
  }
  return 1;
}

int Lrank::add(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  auto &rank = **pp;

  size_t len;
  const char *id = luaL_checklstring(L, 2, &len);
  int64_t score = luaL_checkinteger(L, 3);
  int64_t time = luaL_checkinteger(L, 4);
  Rank_base base{.uid_ = {id, len}, .score_ = score, .time_ = time};
  rank.add(base);
  return 0;
}

int Lrank::dump(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  auto &rank = **pp;

  string ret = rank.dump();
  lua_pushlstring(L, ret.c_str(), ret.size());
  return 1;
}

int Lrank::lrank_gc(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  delete *pp;
  return 0;
}

void Lrank::lrank_meta(lua_State *L) {
  if (luaL_newmetatable(L, LRANK_META)) {
    luaL_Reg l[] = {
        {"add", add}, {"arr_info", arr_info}, {"dump", dump}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, lrank_gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lrank::create_lrank(lua_State *L) {
  int max_num = lua_tointeger(L, 1);
  Rank *p = new Rank();
  if (max_num > 0) p->max_num_ = max_num;
  Rank **pp = (Rank **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  lrank_meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lutil_lrank(lua_State *L) {
  luaL_Reg funcs[] = {{"create_lrank", Lrank::create_lrank}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}
