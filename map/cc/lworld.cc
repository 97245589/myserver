extern "C" {
#include "lauxlib.h"
#include "lua.h"
}
#include <iostream>
using namespace std;

#include "world.h"

static const char *LWORLD_META = "LWORLD_META";

struct Lworld {
  static int gc(lua_State *L);
  static void meta(lua_State *L);
  static int create_lworld(lua_State *L);

  static int init(lua_State *L);
  static int area_entities(lua_State *L);
  static int add_entity(lua_State *L);
  static int del_entity(lua_State *L);
  static int recover_troop(lua_State *L);
  static int add_troop(lua_State *L);
  static int del_troop(lua_State *L);
  static int troops_move(lua_State *L);
  static int troops_info(lua_State *L);
  static int watch_troops(lua_State *L);
  static int add_watch(lua_State *L);
  static int del_watch(lua_State *L);
};

int Lworld::add_watch(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int32_t id = luaL_checkinteger(L, 2);
  int32_t weigh = luaL_checkinteger(L, 3);
  int16_t cx = luaL_checkinteger(L, 4);
  int16_t cy = luaL_checkinteger(L, 5);
  world.add_watch(id, weigh, cx, cy);
  return 0;
}

int Lworld::del_watch(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int32_t id = luaL_checkinteger(L, 2);
  world.del_watch(id);
  return 0;
}

int Lworld::watch_troops(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;

  unordered_map<int32_t, vector<int32_t>> ret;
  world.watch_troops(ret);

  if (ret.size() == 0) return 0;
  lua_createtable(L, 0, ret.size());
  for (auto [wid, arr] : ret) {
    lua_pushinteger(L, wid);
    lua_createtable(L, 0, arr.size());
    for (auto tid : arr) {
      lua_pushinteger(L, tid);
      lua_pushinteger(L, 1);
      lua_settable(L, -3);
    }
    lua_settable(L, -3);
  }
  return 1;
}

int Lworld::troops_info(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;

  auto &troops = world.troops_;
  lua_createtable(L, troops.size() * 4, 0);
  int i = 0;
  for (auto [id, troop] : troops) {
    lua_settop(L, 2);
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
    lua_pushnumber(L, troop.nowx_);
    lua_rawseti(L, -2, ++i);
    lua_pushnumber(L, troop.nowy_);
    lua_rawseti(L, -2, ++i);
    lua_pushinteger(L, troop.nowpos_);
    lua_rawseti(L, -2, ++i);
  }

  return 1;
}

int Lworld::troops_move(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int64_t tm = luaL_checkinteger(L, 2);

  vector<int32_t> arrive;
  world.troops_move(tm, arrive);
  if (arrive.size() == 0) return 0;
  lua_createtable(L, arrive.size(), 0);
  int i = 0;
  for (auto id : arrive) {
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lworld::recover_troop(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;

  Troop troop;
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_getfield(L, 2, "worldid");
  troop.id_ = luaL_checkinteger(L, 3);
  lua_settop(L, 2);
  lua_getfield(L, 2, "nowx");
  troop.nowx_ = luaL_checknumber(L, 3);
  lua_settop(L, 2);
  lua_getfield(L, 2, "nowy");
  troop.nowy_ = luaL_checknumber(L, 3);
  lua_settop(L, 2);
  lua_getfield(L, 2, "nowpos");
  troop.nowpos_ = luaL_checkinteger(L, 3);
  lua_settop(L, 2);
  lua_getfield(L, 2, "tm");
  troop.tm_ = luaL_checkinteger(L, 3);
  lua_settop(L, 2);
  lua_getfield(L, 2, "speed");
  troop.speed_ = luaL_checknumber(L, 3);
  if (troop.speed_ <= 0) return 0;
  lua_settop(L, 2);
  lua_getfield(L, 2, "path");
  luaL_checktype(L, 3, LUA_TTABLE);
  int len = lua_rawlen(L, 3);
  if (len < 4 || len % 2 != 0) {
    return luaL_error(L, "add troop path err");
  }
  vector<int16_t> path;
  for (int i = 1; i <= len; ++i) {
    lua_rawgeti(L, 3, i);
    int16_t v = luaL_checkinteger(L, -1);
    path.push_back(v);
    lua_settop(L, 3);
  }
  troop.path_ = path;

  world.troops_[troop.id_] = troop;
  return 0;
}

int Lworld::add_troop(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int32_t id = luaL_checkinteger(L, 2);
  int64_t tm = luaL_checkinteger(L, 3);
  double speed = luaL_checknumber(L, 4);
  if (speed <= 0) return 0;
  luaL_checktype(L, 5, LUA_TTABLE);
  int len = lua_rawlen(L, 5);
  if (len < 4 || len % 2 != 0) {
    return luaL_error(L, "add troop path err");
  }
  vector<int16_t> path;
  for (int i = 1; i <= len; ++i) {
    lua_rawgeti(L, 5, i);
    int16_t v = luaL_checkinteger(L, -1);
    path.push_back(v);
    lua_settop(L, 5);
  }
  world.add_troop(id, tm, speed, path);
  lua_pushboolean(L, true);
  return 1;
}

int Lworld::del_troop(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int32_t id = luaL_checkinteger(L, 2);
  world.del_troop(id);
  return 0;
}

int Lworld::add_entity(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int16_t cx = luaL_checkinteger(L, 2);
  int16_t cy = luaL_checkinteger(L, 3);
  int16_t len = luaL_checkinteger(L, 4);
  int32_t id = luaL_checkinteger(L, 5);

  vector<int32_t> ids;
  world.add_entity(cx, cy, len, id, ids);
  if (ids.size() == 0) return 0;

  int i = 0;
  lua_createtable(L, ids.size(), 0);
  for (auto id : ids) {
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lworld::del_entity(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int16_t cx = luaL_checkinteger(L, 2);
  int16_t cy = luaL_checkinteger(L, 3);
  int16_t len = luaL_checkinteger(L, 4);

  vector<int32_t> ids;
  world.del_entity(cx, cy, len, ids);
  if (ids.size() == 0) return 0;

  int i = 0;
  lua_createtable(L, ids.size(), 0);
  for (auto id : ids) {
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lworld::init(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;

  int16_t len = luaL_checkinteger(L, 2);
  int16_t wid = luaL_checkinteger(L, 3);
  world.init_world(len, wid);
  return 0;
}

int Lworld::area_entities(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  World &world = **pp;
  int16_t cx = luaL_checkinteger(L, 2);
  int16_t cy = luaL_checkinteger(L, 3);
  int16_t len = luaL_checkinteger(L, 4);

  unordered_set<int32_t> ret;
  world.area_entities(cx, cy, len, ret);
  if (ret.size() == 0) return 0;
  lua_createtable(L, ret.size(), 0);
  int i = 0;
  for (auto id : ret) {
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lworld::gc(lua_State *L) {
  World **pp = (World **)luaL_checkudata(L, 1, LWORLD_META);
  delete *pp;
  return 0;
}

void Lworld::meta(lua_State *L) {
  if (luaL_newmetatable(L, LWORLD_META)) {
    luaL_Reg l[] = {{"init", init},
                    {"area_entities", area_entities},
                    {"add_entity", add_entity},
                    {"del_entity", del_entity},
                    {"recover_troop", recover_troop},
                    {"add_troop", add_troop},
                    {"del_troop", del_troop},
                    {"troops_move", troops_move},
                    {"troops_info", troops_info},
                    {"watch_troops", watch_troops},
                    {"add_watch", add_watch},
                    {"del_watch", del_watch},
                    {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lworld::create_lworld(lua_State *L) {
  World *p = new World();
  World **pp = (World **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lworld_world(lua_State *L) {
  luaL_Reg funcs[] = {{"create_lworld", Lworld::create_lworld}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}