#include <stdlib.h>
#include <zstd.h>

#include "lauxlib.h"
#include "lua.h"

static int lzstd_compress(lua_State *L) {
  size_t len;
  const char *p = lua_tolstring(L, 1, &len);

  int level = lua_tointeger(L, 2);

  int c_buff_size = ZSTD_compressBound(len);
  void *c_buff = malloc(c_buff_size);
  int c_size = ZSTD_compress(c_buff, c_buff_size, p, len, level);

  lua_pushlstring(L, c_buff, c_size);

  free(c_buff);
  return 1;
}

static int lzstd_decompress(lua_State *L) {
  size_t len;
  const char *p = lua_tolstring(L, 1, &len);

  int r_size = ZSTD_getFrameContentSize(p, len);
  void *r_buff = malloc(r_size);

  int d_size = ZSTD_decompress(r_buff, r_size, p, len);
  lua_pushlstring(L, r_buff, d_size);

  free(r_buff);
  return 1;
}

LUAMOD_API int luaopen_lzstd(lua_State *L) {
  luaL_Reg funcs[] = {{"zstd_compress", lzstd_compress},
                      {"zstd_decompress", lzstd_decompress},
                      {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}