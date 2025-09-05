extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>
using namespace std;

struct Rankele {
  string uid_;
  int64_t score_;
  int64_t time_;

  bool operator<(const Rankele &rhs) const {
    if (score_ != rhs.score_) return score_ > rhs.score_;
    if (time_ != rhs.time_) return time_ < rhs.time_;
    return uid_ > rhs.uid_;
  }
};

struct Rank {
  set<Rankele> info_;
  unordered_map<string, set<Rankele>::iterator> id_it_;
  int num_;

  void add(const Rankele &ele) {
    if (auto it = id_it_.find(ele.uid_); it != id_it_.end()) {
      info_.erase(it->second);
      id_it_.erase(it);
    }
    auto [iit, ok] = info_.insert(ele);
    if (ok) id_it_.insert({ele.uid_, iit});
    evict();
  }

  void evict() {
    if (info_.size() <= num_) return;
    auto it = info_.rbegin();
    if (it == info_.rend()) return;
    auto uid = it->uid_;
    id_it_.erase(uid);
    info_.erase(*it);
  }

  void dump() {
    ostringstream oss;
    oss << "rank_size: " << info_.size() << endl;
    oss << "idit_size: " << id_it_.size() << endl;
    oss << "num: " << num_ << endl;
    for (auto &ele : info_) {
      oss << ele.uid_ << "," << ele.score_ << "," << ele.time_ << "|";
    }
    oss << endl;
    cout << oss.str() << endl;
  }
};

static const char *LRANK_META = "LRANK_META";

struct Lrank {
  static int create_lrank(lua_State *L);
  static void lrank_meta(lua_State *L);
  static int lrank_gc(lua_State *L);

  static int add(lua_State *L);
  static int info(lua_State *L);
};

int Lrank::info(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  auto &rank = **pp;

  auto &info = rank.info_;
  const int isize = info.size();
  if (isize == 0) return 0;

  lua_createtable(L, 0, 2);
  lua_createtable(L, 3 * isize, 0);
  lua_createtable(L, 0, isize);
  int i = 0;
  for (auto &data : info) {
    auto &uid = data.uid_;
    auto score = data.score_;
    auto time = data.time_;
    lua_pushlstring(L, uid.c_str(), uid.size());
    lua_rawseti(L, -3, i * 3 + 1);
    lua_pushinteger(L, score);
    lua_rawseti(L, -3, i * 3 + 2);
    lua_pushinteger(L, time);
    lua_rawseti(L, -3, i * 3 + 3);

    lua_pushlstring(L, uid.c_str(), uid.size());
    lua_pushinteger(L, i + 1);
    lua_settable(L, -3);
    ++i;
  }
  lua_setfield(L, -3, "map");
  lua_setfield(L, -2, "arr");
  return 1;
}

int Lrank::add(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  auto &rank = **pp;

  size_t len;
  const char *id = luaL_checklstring(L, 2, &len);
  int64_t score = luaL_checkinteger(L, 3);
  int64_t time = luaL_checkinteger(L, 4);
  Rankele ele{.uid_ = {id, len}, .score_ = score, .time_ = time};
  rank.add(ele);
  return 0;
}

int Lrank::lrank_gc(lua_State *L) {
  Rank **pp = (Rank **)luaL_checkudata(L, 1, LRANK_META);
  delete *pp;
}

void Lrank::lrank_meta(lua_State *L) {
  if (luaL_newmetatable(L, LRANK_META)) {
    luaL_Reg l[] = {{"add", add}, {"info", info}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, lrank_gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lrank::create_lrank(lua_State *L) {
  int max_num = luaL_checkinteger(L, 1);
  if (max_num <= 0) return 0;
  Rank *p = new Rank();
  p->num_ = max_num;
  Rank **pp = (Rank **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  lrank_meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lutil_rank(lua_State *L) {
  luaL_Reg funcs[] = {{"create_rank", Lrank::create_lrank}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}
