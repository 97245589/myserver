extern "C" {
#include "lapi.h"
#include "lauxlib.h"
}

#include "jps.hpp"

static const char *LJPS_META = "LJPS_META";

struct Ljps {
  static int init_map(lua_State *L);
  static int set_block(lua_State *L);
  static int set_cache(lua_State *L);
  static int get_cache(lua_State *L);
  static int path(lua_State *L);

  static int gc(lua_State *L);
  static void meta(lua_State *L);
  static int create_ljps(lua_State *L);
};

int Ljps::get_cache(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  auto &jps = **pp;

  int8_t dx = luaL_checkinteger(L, 2);
  int8_t dy = luaL_checkinteger(L, 3);
  string ret = jps.dump_jp_cache({dx, dy});
  lua_pushlstring(L, ret.c_str(), ret.size());
  return 1;
}

int Ljps::path(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  auto &jps = **pp;

  int16_t sx = luaL_checkinteger(L, 2);
  int16_t sy = luaL_checkinteger(L, 3);
  int16_t ex = luaL_checkinteger(L, 4);
  int16_t ey = luaL_checkinteger(L, 5);

  bool quick = lua_toboolean(L, 6);
  jps.quick_ = quick;
  vector<Pos> ret;
  jps.pathfind({sx, sy}, {ex, ey}, ret);
  jps.quick_ = 0;

  if (0 == ret.size()) return 0;
  lua_createtable(L, ret.size() * 2, 0);
  int i = 0;
  for (int j = ret.size() - 1; j >= 0; --j) {
    auto p = ret[j];
    lua_pushinteger(L, p.x_);
    lua_rawseti(L, -2, ++i);
    lua_pushinteger(L, p.y_);
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Ljps::init_map(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  auto &jps = **pp;

  int16_t len = luaL_checkinteger(L, 2);
  int16_t wid = luaL_checkinteger(L, 3);
  jps.world_.init_world(len, wid);
  return 0;
}

int Ljps::set_block(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  auto &jps = **pp;

  int16_t minx = luaL_checkinteger(L, 2);
  int16_t miny = luaL_checkinteger(L, 3);
  int16_t maxx = luaL_checkinteger(L, 4);
  int16_t maxy = luaL_checkinteger(L, 5);
  int8_t v = lua_tointeger(L, 6);
  jps.world_.set_block(minx, miny, maxx, maxy, v);
  bool update_cache = lua_toboolean(L, 7);
  if (update_cache) {
    jps.block_jp_cache(minx, miny, maxx, maxy);
  }
  return 0;
}

int Ljps::set_cache(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  auto &jps = **pp;
  jps.init_jp_cache();
  return 0;
}

int Ljps::gc(lua_State *L) {
  Jps **pp = (Jps **)luaL_checkudata(L, 1, LJPS_META);
  delete *pp;
  return 0;
}

void Ljps::meta(lua_State *L) {
  if (luaL_newmetatable(L, LJPS_META)) {
    luaL_Reg l[] = {{"path", path},           {"set_cache", set_cache},
                    {"set_block", set_block}, {"init_map", init_map},
                    {"get_cache", get_cache}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Ljps::create_ljps(lua_State *L) {
  Jps *p = new Jps();
  Jps **pp = (Jps **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

static const struct luaL_Reg funcs[] = {{"create_ljps", Ljps::create_ljps},
                                        {NULL, NULL}};
extern "C" {
LUAMOD_API int luaopen_lworld_jps(lua_State *L) {
  luaL_newlib(L, funcs);
  return 1;
}
}