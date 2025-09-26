extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

#include <fnmatch.h>

#include <functional>
#include <iostream>
#include <string>
#include <vector>
using namespace std;

#include "leveldb/cache.h"
#include "leveldb/db.h"
#include "leveldb/write_batch.h"

static const char *LLEVELDB_META = "LLEVELDB_META";

struct Lleveldb {
  leveldb::DB *db_;

  static int create(lua_State *L);
  static void meta(lua_State *L);
  static int gc(lua_State *L);

  static int realkeys(lua_State *L);
  static int keys(lua_State *L);
  static int del(lua_State *L);
  static int hmset(lua_State *L);
  static int hkeys(lua_State *L);
  static int hgetall(lua_State *L);
  static int hget(lua_State *L);
  static int hset(lua_State *L);
  static int hdel(lua_State *L);
  static int hmget(lua_State *L);

  static void search_key(
      leveldb::DB *&db, string str,
      function<void(const string &, const string &, const string &)> func);

  const static char split_ = 0xff;
};

int Lleveldb::hget(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t lk;
  const char *pk = luaL_checklstring(L, 2, &lk);
  size_t lhk;
  const char *phk = luaL_checklstring(L, 3, &lhk);
  string key{pk, lk};
  string hkey{phk, lhk};
  key = key + split_ + hkey;

  string val;
  leveldb::Status status = db->Get(leveldb::ReadOptions(), key, &val);
  if (status.ok()) {
    lua_pushlstring(L, val.c_str(), val.size());
    return 1;
  } else {
    return 0;
  }
}

int Lleveldb::hset(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t lk;
  const char *pk = luaL_checklstring(L, 2, &lk);
  size_t lhk;
  const char *phk = luaL_checklstring(L, 3, &lhk);
  string key{pk, lk};
  string hkey{phk, lhk};
  key = key + split_ + hkey;

  size_t lv;
  const char *pv = luaL_checklstring(L, 4, &lv);
  db->Put(leveldb::WriteOptions(), key, {pv, lv});
  return 0;
}

int Lleveldb::hdel(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t lk;
  const char *pk = luaL_checklstring(L, 2, &lk);
  size_t lhk;
  const char *phk = luaL_checklstring(L, 3, &lhk);
  string key{pk, lk};
  string hkey{phk, lhk};
  key = key + split_ + hkey;

  db->Delete(leveldb::WriteOptions(), key);
  return 0;
}

int Lleveldb::realkeys(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
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

void Lleveldb::search_key(
    leveldb::DB *&db, string str,
    function<void(const string &, const string &, const string &)> func) {
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
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ppat = luaL_checklstring(L, 2, &len);
  string patt{ppat, len};

  vector<string> keys;
  leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
  for (it->SeekToFirst(); it->Valid(); it->Next()) {
    string k = it->key().ToString();
    int p = k.find(split_);
    if (p < 0 || p >= k.size() - 1) continue;

    string key = k.substr(0, p);
    if (0 != fnmatch(patt.c_str(), key.c_str(), 0)) continue;
    if (keys.empty() || keys.back() != key) {
      keys.push_back(key);
    }
  }
  delete it;

  lua_createtable(L, keys.size(), 0);
  int i = 0;
  for (auto key : keys) {
    lua_pushlstring(L, key.c_str(), key.size());
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lleveldb::del(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ps = luaL_checklstring(L, 2, &len);
  string str = {ps, len};

  leveldb::WriteBatch batch;

  search_key(db, str,
             [&](const string &key, const string &val, const string &realkey) {
               batch.Delete(realkey);
             });

  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::hkeys(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ps = luaL_checklstring(L, 2, &len);
  string str{ps, len};
  int i = 0;
  lua_createtable(L, 0, 0);
  search_key(db, str,
             [&](const string &key, const string &val, const string &realkey) {
               lua_pushlstring(L, key.c_str(), key.size());
               lua_rawseti(L, -2, ++i);
             });
  return 1;
}

int Lleveldb::hgetall(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  size_t len;
  const char *ps = luaL_checklstring(L, 2, &len);
  string str = {ps, len};

  lua_createtable(L, 0, 0);
  int i = 0;
  search_key(db, str,
             [&](const string &key, const string &val, const string &realkey) {
               lua_pushlstring(L, key.c_str(), key.size());
               lua_rawseti(L, -2, ++i);
               lua_pushlstring(L, val.c_str(), val.size());
               lua_rawseti(L, -2, ++i);
             });

  return 1;
}

int Lleveldb::hmset(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  int pnum = lua_gettop(L);
  if (pnum < 4 || pnum % 2 != 0) {
    return luaL_error(L, "leveldb hmset len arr");
  }
  size_t lk;
  const char *pk = luaL_checklstring(L, 2, &lk);
  string key{pk, lk};

  leveldb::WriteBatch batch;
  for (int i = 3; i < pnum; i += 2) {
    size_t lhk;
    const char *phk = luaL_checklstring(L, i, &lhk);
    string hkey{phk, lhk};
    string rkey = key + split_ + hkey;
    size_t lv;
    const char *pv = luaL_checklstring(L, i + 1, &lv);
    string val{pv, lv};
    batch.Put(rkey, val);
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::hmget(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  leveldb::DB *db = p->db_;

  int pnum = lua_gettop(L);
  if (pnum < 3) {
    return luaL_error(L, "leveldb hmget len arr");
  }

  size_t lk;
  const char *pk = luaL_checklstring(L, 2, &lk);
  string key{pk, lk};
  lua_createtable(L, pnum - 2, 0);
  for (int i = 3; i <= pnum; ++i) {
    size_t lhk;
    const char *phk = luaL_checklstring(L, i, &lhk);
    string hkey{phk, lhk};
    string rkey = key + split_ + hkey;
    string val;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), rkey, &val);
    if (s.ok()) {
      lua_pushlstring(L, val.c_str(), val.size());
    } else {
      lua_pushnil(L);
    }
    lua_rawseti(L, -2, i - 2);
  }
  return 1;
}

int Lleveldb::gc(lua_State *L) {
  Lleveldb *p = (Lleveldb *)luaL_checkudata(L, 1, LLEVELDB_META);
  delete p->db_;
  return 0;
}

void Lleveldb::meta(lua_State *L) {
  if (luaL_newmetatable(L, LLEVELDB_META)) {
    luaL_Reg l[] = {
        {"del", del},           {"hmset", hmset},     {"hmget", hmget},
        {"hkeys", hkeys},       {"hgetall", hgetall}, {"hget", hget},
        {"hset", hset},         {"hdel", hdel},       {"keys", keys},
        {"realkeys", realkeys}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lleveldb::create(lua_State *L) {
  size_t len;
  const char *pname = luaL_checklstring(L, 1, &len);

  leveldb::DB *db;
  leveldb::Options options;
  options.create_if_missing = true;
  options.compression = leveldb::kNoCompression;
  options.write_buffer_size = 16 * 1024 * 1024;
  options.max_file_size = 8 * 1024 * 1024;
  options.block_size = 16 * 1024;
  leveldb::Status status = leveldb::DB::Open(options, {pname, len}, &db);

  if (!status.ok()) {
    return luaL_error(L, "leveldb open err");
  }

  Lleveldb *pl = (Lleveldb *)lua_newuserdata(L, sizeof(Lleveldb));
  pl->db_ = db;

  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lleveldb(lua_State *L) {
  luaL_Reg funcs[] = {{"create", Lleveldb::create}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}
