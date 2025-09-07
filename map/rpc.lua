local require, print, dump = require, print, dump
local pairs = pairs
local cmds = require "common.service.cmds"
local world = require "map.world"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local gamecommon = require "server.game.game_common"

local cluster_name = skynet.getenv("server_name") .. skynet.getenv("server_id")

local playerid_src = {}
local watchid_playerid = {}

local send = function(watchid, obj)
    local playerid = watchid_playerid[watchid]
    if not playerid then
        return
    end
    local src = playerid_src[playerid]
    if src == 1 then
        gamecommon.send_player_service("map_notify", playerid, obj)
    else
        cluster.send(src, gamecommon.get_player_service(playerid), "map_notify", playerid, obj)
    end
end

local handle = {
    entityadd = function(watchids, entity)
        for _, watchid in pairs(watchids) do
            send(watchid, {
                addentity = entity
            })
        end
    end,
    entitydel = function(watchids, entity)
        for _, watchid in pairs(watchids) do
            send(watchid, {
                delentity = entity.worldid
            })
        end
    end,
    troopupdate = function(watchid, obj)
        send(watchid, {
            troopupdate = obj
        })
    end
}

world.notify_watches = function(cmd, ...)
    handle[cmd](...)
end

cmds.init = function(mtp)
    local mgr = require("map." .. mtp .. ".impl")
    mgr.init()
end

cmds.exit = function()
    skynet.exit()
end

cmds.player_enter = function(playerid, src_server, weigh, cx, cy)
    print("==== map player enter", playerid, src_server, weigh, cx, cy)
    local watchid = world.add_watch(playerid, weigh, cx, cy)
    watchid_playerid[watchid] = playerid
    if src_server == cluster_name then
        playerid_src[playerid] = 1
    else
        playerid_src[playerid] = src_server
    end
    return world.area_entities(cx, cy, 2)
end

cmds.player_leave = function(playerid)
    print("==== map player leave", playerid)
    playerid_src[playerid] = nil
    local watchid = world.del_watch(playerid)
    if watchid then
        watchid_playerid[watchid] = nil
    end
end

