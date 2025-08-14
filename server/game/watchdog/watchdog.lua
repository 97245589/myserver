local require, table = require, table
local print, dump = print, dump
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local proto = require"common.service.config_load".proto()
local gamecommon = require "server.game.game_common"

local host = proto.host

local gate = skynet.newservice("gate")
skynet.call(gate, "lua", "open", {
    port = skynet.getenv("gate_port"),
    maxclient = 8888,
    nodelay = true
})

local close_conn = function(fd)
    print("watchdog close_conn", fd)
    skynet.send(gate, "lua", "kick", fd)
end

local socket_cmd = {
    open = function(fd, addr)
        skynet.send(gate, "lua", "accept", fd)
    end,
    close = function(fd)
        skynet.send("verify", "lua", "close", fd)
    end,
    error = function(fd, msg)
        print("socket error", fd, msg)
        close_conn(fd)
    end,
    warning = function(fd, size)
        print("socket warning", fd, size)
    end,
    data = function(fd, msg)
        skynet.send("verify", "lua", "data", fd, msg, gate)
    end
}
cmds.socket = function(sub_cmd, ...)
    local f = socket_cmd[sub_cmd]
    if f then
        f(...)
    end
end

cmds.close_conn = close_conn
