local require = require
local skynet = require "skynet"
local gamecommon = require "server.game.game_common"

local mapaddrs = {
    server = {}
}

local add_map = function(tp)
    local addr = skynet.newservice("map/start")
    skynet.send(addr, "lua", "init", tp)
    mapaddrs.server[tp] = addr
end

local del_map = function(tp)
    local addr = mapaddrs.server[tp]
    mapaddrs.server[tp] = nil
    skynet.send(addr, "lua", "exit")
end

-- add_map("test")
add_map("game")
skynet.timeout(100, function()
    gamecommon.send_all_player_service("set_mapaddrs", mapaddrs)
end)
