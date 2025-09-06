local require, print, dump = require, print, dump
local pairs = pairs
local cmds = require "common.service.cmds"
local world = require "map.world"
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local watchid_playerid = {}

local handle = {
    entityadd = function(watchids, entity)
    end,
    entitydel = function(watchids, entity)
    end,
    troopupdate = function(obj)
        for watchid, info in pairs(obj) do
        end
    end
}

world.notify_watches = function(cmd, ...)
    handle[cmd](...)
end

cmds.init = function(mtp)
    local mgr = require("map." .. mtp .. ".impl")
    mgr.init()
end

cmds.add_watch = function(playerid, cx, cy)
    local watchid = world.add_watch(playerid, 1, cx, cy)
    watchid_playerid[watchid] = playerid
end

cmds.del_watch = function(playerid)
    local watchid = world.del_watch(playerid)
    if watchid then
        watchid_playerid[watchid] = nil
    else
        print("del watch err no watchid", playerid)
    end
end

cmds.exit = function()
    skynet.exit()
end
