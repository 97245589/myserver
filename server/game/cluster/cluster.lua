local require, print, dump = require, print, dump
local cluster_start = require "common.service.cluster_start"
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local cluster = require "skynet.cluster"
local cmds = require "common.service.cmds"
local gamecommon = require "server.game.game_common"
local env = require "common.func.env"

local serverid = env.server_id()
local gameserver_info = {
    serverid = serverid,
    host = env.game_outer_host()
}

cmds.gameserver_info = function()
    return gameserver_info
end

cmds.all_cluster_node = function()
    return cluster_start.get_cluster_node()
end

cmds.set_mapaddrs = function(clustername, addrs)
    -- print("game cluster set mapaddrs", clustername, dump(addrs))
    gamecommon.send_all_player_service("set_mapaddrs", clustername, addrs)
end
