local require, os = require, os
local skynet = require "skynet"
local mgrs = require "server.game.player.mgrs"
local enums = require "common.func.enums"
local task_mgr = require "server.game.player.mgr.task_mgr"
local push = require"server.game.player.client_req".push

local M = {}

M.init_player = function(player)
    player.role = player.role or {}
    local role = player.role
    role.acc = player.acc
    role.playerid = player.playerid
    role.level = role.level or 1
end

M.tick_player = function(player)
    push(player.playerid, "push_test", {test=0})
end

M.levelup = function(player)
    local role = player.role
    role.level = role.level + 1
    task_mgr.trigger_event(player, {enums.task_player_level, role.level})
end

mgrs.add_mgr("role", M)
return M
