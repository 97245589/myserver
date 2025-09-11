#include "ikcp.h"
extern "C"
{
#include <string.h>

#include "lauxlib.h"
#include "lua.h"
#include "skynet.h"
#include "skynet_socket.h"
}

#include <iostream>
using namespace std;

const static char *LKCP_META = "LKCP_META";

struct Kcp_user
{
  skynet_context *ctx;
  int host;
  int conv;
  char address[20];
};

struct Lkcp
{
  static int lkcp_recv(lua_State *L);
  static int lkcp_send(lua_State *L);
  static int lkcp_update(lua_State *L);

  static int lkcp_gc(lua_State *L);
  static void lkcp_meta(lua_State *L);
  static int udp_output(const char *buf, int len, ikcpcb *kcp, void *user);
  static int create_lkcp(lua_State *L);

  static int lkcp_client(lua_State *L);
  static int cli_output(const char *buf, int len, ikcpcb *kcp, void *user);
};

int Lkcp::lkcp_gc(lua_State *L)
{
  ikcpcb **pp = (ikcpcb **)luaL_checkudata(L, 1, LKCP_META);
  ikcpcb *p = *pp;
  delete (Kcp_user *)(p->user);
  ikcp_release(p);
  return 0;
}

int Lkcp::lkcp_send(lua_State *L)
{
  ikcpcb **pp = (ikcpcb **)luaL_checkudata(L, 1, LKCP_META);
  ikcpcb *p = *pp;
  size_t len = 0;
  const char *str = luaL_checklstring(L, 2, &len);
  ikcp_send(p, str, len);
  return 0;
}

int Lkcp::lkcp_update(lua_State *L)
{
  ikcpcb **pp = (ikcpcb **)luaL_checkudata(L, 1, LKCP_META);
  ikcpcb *p = *pp;
  int64_t i = luaL_checkinteger(L, 2);
  ikcp_update(p, i * 10);
  return 0;
}

int Lkcp::lkcp_recv(lua_State *L)
{
  ikcpcb **pp = (ikcpcb **)luaL_checkudata(L, 1, LKCP_META);
  ikcpcb *p = *pp;
  size_t slen = 0;
  const char *str = luaL_checklstring(L, 2, &slen);
  ikcp_input(p, str, slen);

  char buf[1024 * 100];
  int len = ikcp_recv(p, buf, sizeof(buf));
  if (len > 0)
  {
    lua_pushlstring(L, buf, len);
    return 1;
  }
  else
  {
    return 0;
  }
}

void Lkcp::lkcp_meta(lua_State *L)
{
  if (luaL_newmetatable(L, LKCP_META))
  {
    luaL_Reg l[] = {{"send", lkcp_send},
                    {"update", lkcp_update},
                    {"recv", lkcp_recv},
                    {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, lkcp_gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lkcp::udp_output(const char *buf, int len, ikcpcb *kcp, void *user)
{
  Kcp_user *kuser = (Kcp_user *)user;
  socket_sendbuffer sbuf;
  sbuf.id = kuser->host;
  sbuf.type = SOCKET_BUFFER_RAWPOINTER;
  sbuf.buffer = buf;
  sbuf.sz = len;
  int err = skynet_socket_udp_sendbuffer(kuser->ctx, kuser->address, &sbuf);
  return 0;
}

int Lkcp::create_lkcp(lua_State *L)
{
  lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
  skynet_context *ctx = (skynet_context *)lua_touserdata(L, -1);
  if (ctx == NULL)
  {
    return luaL_error(L, "Init skynet context first");
  }

  int conv = luaL_checkinteger(L, 1);
  int host = luaL_checkinteger(L, 2);
  Kcp_user *kuser = new Kcp_user();
  kuser->ctx = ctx;
  kuser->conv = conv;
  kuser->host = host;
  size_t sz = 0;
  const char *str = luaL_checklstring(L, 3, &sz);
  if (sz >= sizeof(kuser->address))
  {
    return luaL_error(L, "kcp address len error");
  }
  memcpy(kuser->address, str, sz);

  ikcpcb *p = ikcp_create(conv, kuser);
  p->output = udp_output;
  // ikcp_nodelay(p, 0, 10, 0, 0);
  ikcp_nodelay(p, 2, 10, 2, 1);
  ikcpcb **pp = (ikcpcb **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  lkcp_meta(L);
  return 1;
}

int Lkcp::cli_output(const char *buf, int len, ikcpcb *kcp, void *user)
{
  Kcp_user *kuser = (Kcp_user *)user;
  socket_sendbuffer sbuf;
  sbuf.id = kuser->host;
  sbuf.type = SOCKET_BUFFER_RAWPOINTER;
  sbuf.buffer = buf;
  sbuf.sz = len;
  int err = skynet_socket_sendbuffer(kuser->ctx, &sbuf);
  return 0;
}

int Lkcp::lkcp_client(lua_State *L)
{
  lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
  skynet_context *ctx = (skynet_context *)lua_touserdata(L, -1);
  if (ctx == NULL)
  {
    return luaL_error(L, "Init skynet context first");
  }

  int conv = luaL_checkinteger(L, 1);
  int host = luaL_checkinteger(L, 2);
  Kcp_user *kuser = new Kcp_user();
  kuser->ctx = ctx;
  kuser->conv = conv;
  kuser->host = host;

  ikcpcb *p = ikcp_create(conv, kuser);
  p->output = cli_output;
  ikcp_nodelay(p, 2, 10, 2, 1);
  ikcpcb **pp = (ikcpcb **)lua_newuserdata(L, sizeof(p));
  *pp = p;
  lkcp_meta(L);
  return 1;
}

extern "C"
{
  LUAMOD_API int luaopen_lkcp(lua_State *L)
  {
    luaL_Reg l[] = {{"create_lkcp", Lkcp::create_lkcp},
                    {"lkcp_client", Lkcp::lkcp_client},
                    {NULL, NULL}};
    luaL_newlib(L, l);
    return 1;
  }
}
