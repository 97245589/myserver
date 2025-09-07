local requrie, print, dump = require, print, dump
local skynet = require "skynet"

local mapaddrs = {}

local addr = skynet.newservice("map/start")
skynet.send(addr, "lua", "init", "game")
mapaddrs.game = addr

skynet.send("cluster", "lua", "set_mapaddrs", mapaddrs)
