local require, print, dump = require, print, dump
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local client_req = require "server.game.player.client_req"
local pacts_tm = require "server.game.player.mgr.pacts_tm"
local map = require "server.game.player.map"
local push = client_req.push

cmds.player_enter = client_req.player_enter

cmds.acts_tm_notify = pacts_tm.acts_tm_notify

cmds.set_mapaddrs = map.set_mapaddrs

cmds.map_notify = function(playerid, obj)
    -- print("map_notify", playerid, dump(obj))
    push(playerid, "push_mapinfo", obj)
end
