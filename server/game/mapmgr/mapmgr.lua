local require = require
local skynet = require "skynet"

local mapaddrs = {}

local addr = skynet.newservice("map/start")
skynet.send(addr, "lua", "init", "test")
mapaddrs.test = addr

local addr = skynet.newservice("map/start")
skynet.send(addr, "lua", "init", "game")
mapaddrs.game = addr
skynet.send(mapaddrs.game, "lua", "exit")
