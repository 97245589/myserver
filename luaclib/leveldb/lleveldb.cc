extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

#include <functional>
#include <iostream>
#include <map>
#include <string>
using namespace std;

#include "leveldb/cache.h"
#include "leveldb/db.h"
#include "leveldb/filter_policy.h"
#include "leveldb/write_batch.h"

static const char *LLEVELDB_META = "LLEVELDB_META";

struct Leveldb_data {
  leveldb::DB *db_;
  leveldb::Cache *cache_;
  const leveldb::FilterPolicy *filter_;
};

struct Lleveldb {
  static int create_lleveldb(lua_State *L);
  static void lleveldb_meta(lua_State *L);
  static int lleveldb_gc(lua_State *L);

  static int realkeys(lua_State *L);

  static int del(lua_State *L);
  static int hmset(lua_State *L);
  static int hgetall(lua_State *L);
  static int keys(lua_State *L);
  static int hdel(lua_State *L);
  static int hmget(lua_State *L);

  static void search_key(leveldb::DB *&db, string str,
                         function<void(string, string, string)> func);

  const static char split_ = 0xff;
};

int Lleveldb::hmget(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  luaL_checktype(L, 2, LUA_TTABLE);
  uint32_t len = lua_rawlen(L, 2);
  if (0 == len) {
    return luaL_error(L, "leveldb hmget len arr");
  }

  lua_createtable(L, 0, len);
  for (int i = 0; i < len; ++i) {
    lua_rawgeti(L, 2, i + 1);
    size_t lk;
    const char *pk = lua_tolstring(L, -1, &lk);
    std::string val;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), {pk, lk}, &val);
    if (s.ok()) {
      string str = {pk, lk};
      int p = str.find(split_);
      if (p < 0 || p >= str.size() - 1) {
        continue;
      }
      string key = str.substr(p + 1);
      lua_pushlstring(L, key.c_str(), key.size());
      lua_pushlstring(L, val.c_str(), val.size());
      lua_settable(L, 3);
    }
    lua_settop(L, 3);
  }
  return 1;
}

int Lleveldb::hdel(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  luaL_checktype(L, 2, LUA_TTABLE);
  uint32_t len = lua_rawlen(L, 2);
  if (0 == len) {
    return luaL_error(L, "leveldb hdel len arr");
  }

  leveldb::WriteBatch batch;
  for (int i = 0; i < len; ++i) {
    lua_settop(L, 2);
    lua_rawgeti(L, 2, i + 1);
    size_t lk;
    const char *pk = lua_tolstring(L, 3, &lk);
    batch.Delete({pk, lk});
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::realkeys(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  lua_createtable(L, 0, 0);
  int i = 1;
  leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
  for (it->SeekToFirst(); it->Valid(); it->Next()) {
    const string &k = it->key().ToString();
    lua_pushlstring(L, k.c_str(), k.size());
    lua_rawseti(L, -2, i++);
  }
  delete it;
  return 1;
}

void Lleveldb::search_key(leveldb::DB *&db, string str,
                          function<void(string, string, string)> func) {
  string start = str + split_;
  string end = start + char(0xff);

  leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());

  for (it->Seek(start); it->Valid() && it->key().ToString() < end; it->Next()) {
    string k = it->key().ToString();

    if (k.size() <= start.size()) {
      continue;
    }
    if (k.substr(0, start.size()) != start) {
      continue;
    }

    string key = k.substr(start.size());
    string val = it->value().ToString();
    func(key, val, k);
  }

  delete it;
}

int Lleveldb::keys(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  map<string, int> keys;
  leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
  for (it->SeekToFirst(); it->Valid(); it->Next()) {
    string k = it->key().ToString();
    int p = k.find(split_);
    if (p < 0 || p >= k.size() - 1) {
      continue;
    }
    string key = k.substr(0, p);
    keys[key]++;
  }

  lua_createtable(L, keys.size(), 0);
  int i = 1;
  for (auto [k, v] : keys) {
    lua_pushlstring(L, k.c_str(), k.size());
    lua_rawseti(L, -2, i++);
  }
  delete it;
  return 1;
}

int Lleveldb::del(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ps = luaL_checklstring(L, 2, &len);
  string str = {ps, len};

  leveldb::WriteBatch batch;

  search_key(db, str, [&](string key, string val, string realkey) {
    batch.Delete(realkey);
  });

  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::hgetall(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ps = luaL_checklstring(L, 2, &len);
  string str = {ps, len};

  lua_createtable(L, 0, 0);
  search_key(db, str, [&](string key, string val, string realkey) {
    lua_pushlstring(L, key.c_str(), key.size());
    lua_pushlstring(L, val.c_str(), val.size());
    lua_settable(L, -3);
  });

  return 1;
}

int Lleveldb::hmset(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  luaL_checktype(L, 2, LUA_TTABLE);
  uint32_t len = lua_rawlen(L, 2);
  if (len <= 0 || len % 2 != 0) {
    return luaL_error(L, "leveldb hmset len err");
  }

  leveldb::WriteBatch batch;
  for (int i = 0; i < len; i += 2) {
    lua_settop(L, 2);
    lua_rawgeti(L, 2, i + 1);
    size_t lk, lv;
    const char *pk = lua_tolstring(L, 3, &lk);
    lua_rawgeti(L, 2, i + 2);
    const char *pv = lua_tolstring(L, 4, &lv);
    batch.Put({pk, lk}, {pv, lv});
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::lleveldb_gc(lua_State *L) {
  Leveldb_data *p = (Leveldb_data *)luaL_checkudata(L, 1, LLEVELDB_META);
  delete p->db_;
  delete p->cache_;
  delete p->filter_;
}

void Lleveldb::lleveldb_meta(lua_State *L) {
  if (luaL_newmetatable(L, LLEVELDB_META)) {
    luaL_Reg l[] = {{"del", del},           {"hmset", hmset}, {"hmget", hmget},
                    {"hgetall", hgetall},   {"hdel", hdel},   {"keys", keys},
                    {"realkeys", realkeys}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, lleveldb_gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lleveldb::create_lleveldb(lua_State *L) {
  size_t len;
  const char *p = luaL_checklstring(L, 1, &len);
  string name = {p, len};
  uint32_t cache_len = luaL_checkinteger(L, 2);

  leveldb::DB *db;
  leveldb::Options options;
  options.block_cache = leveldb::NewLRUCache(cache_len);
  options.filter_policy = leveldb::NewBloomFilterPolicy(10);
  options.create_if_missing = true;
  leveldb::Status status = leveldb::DB::Open(options, name, &db);

  if (!status.ok()) {
    return luaL_error(L, "leveldb open err");
  }

  Leveldb_data *pl = (Leveldb_data *)lua_newuserdata(L, sizeof(Leveldb_data));
  pl->db_ = db;
  pl->cache_ = options.block_cache;
  pl->filter_ = options.filter_policy;

  lleveldb_meta(L);
  return 1;
}

static const struct luaL_Reg funcs[] = {
    {"create_lleveldb", Lleveldb::create_lleveldb}, {NULL, NULL}};

extern "C" {
LUAMOD_API int luaopen_lleveldb(lua_State *L) {
  luaL_newlib(L, funcs);
  return 1;
}
}