local require = require
local skynet = require "skynet"
local mgrs = require "server.game.player.mgrs"
local zstd = require "common.tool.zstd"

local players = {}
local get_player_from_db = function(playerid)
    local player = {}
    if players[playerid] then
        return players[playerid]
    end
    mgrs.all_init_player(player)
    player.playerid = playerid
    players[playerid] = player
    return player
end

local M = {}

M.get_player = function(playerid)
    local player = players[playerid] or get_player_from_db(playerid)

    player.opttm = skynet.now()
    return player
end

M.players = players

return M
