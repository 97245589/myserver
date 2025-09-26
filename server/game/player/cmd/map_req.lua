local require, print, dump = require, print, dump
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local client_req = require "server.game.player.client_req"
local req = client_req.client_req
local map = require "server.game.player.map"
local env = require "common.func.env"

local cluster_name = env.clusetr_name()

req.enter_world = function(player, args)
    local ret = map.call(player, "player_enter", player.playerid, cluster_name, 1, 50, 50)
    return {
        code = 0,
        entities = ret
    }
end
