local require = require
local skynet = require "skynet"
local gamecommon = require "server.game.game_common"

local cluster_name = skynet.getenv("server_name") .. skynet.getenv("server_id")

local mapaddrs = {}

local add_map = function(tp)
    local addr = skynet.newservice("map/start")
    skynet.send(addr, "lua", "init", tp)
    mapaddrs[tp] = addr
end

local del_map = function(tp)
    local addr = mapaddrs[tp]
    mapaddrs[tp] = nil
    skynet.send(addr, "lua", "exit")
end

add_map("test")
skynet.timeout(6000, function ()
    del_map("test")
end)
add_map("game")
skynet.timeout(100, function()
    gamecommon.send_all_player_service("set_mapaddrs", cluster_name, mapaddrs)
end)
