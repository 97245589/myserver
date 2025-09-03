local require, os, print, pcall = require, os, print, pcall
local next, pairs = next, pairs
local skynet = require "skynet"
local zstd = require "common.tool.zstd"
local mgrs = require "server.game.player.mgrs"

local profile = require "skynet.profile"
local profile_info = require "common.service.profile"

local client_req = require "server.game.player.client_req"
local kick_player = client_req.kick_player
local players = require "server.game.player.players"
local players = players.players

local OFFLINE_TM = 100 * 300
local TICK_SAVE_NUM = 5

local gen_ids = function(ids, obj)
    if next(ids) then
        return ids
    end
    local ret = {}
    for k, _ in pairs(obj) do
        ret[k] = 1
    end
    return ret
end

local offline_player = function(player, playerid)
    if skynet.now() > player.opttm + OFFLINE_TM then
        client_req.kick_player(playerid)
        players[playerid] = nil
    end
end

local playerids = {}
local tick_save_player = function()
    playerids = gen_ids(playerids, players, 1)
    local i = 1
    for playerid, _ in pairs(playerids) do
        local player = players[playerid]
        -- print("save player ...", playerid, zstd.pack(player))
        offline_player(player, playerid)
        playerids[playerid] = nil
        i = i + 1
        if i > TICK_SAVE_NUM then
            return
        end
    end
end

local tick_save = function()
    profile.start()

    tick_save_player()

    local time = profile.stop()
    local cmd_name = "tick_save_player"
    profile_info.add_cmd_profile(cmd_name, time)
end

skynet.fork(function()
    while true do
        skynet.sleep(100)
        local ok, ret = pcall(function()
            tick_save()
            mgrs.all_tick()
            for playerid, player in pairs(players) do
                mgrs.all_tick_player(player)
            end
        end)
        if not ok then
            print("tick err", ret)
        end
    end
end)
