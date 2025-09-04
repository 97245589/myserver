local require, print, dump = require, print, tdump
local skynet = require "skynet"
local mgrs = require "server.game.player.mgrs"
local task_mgr = require "server.game.player.mgr.task_mgr"
local config = require"common.service.config_load".excel_config

local task_cfg = config("task_test")

local M = {}

M.init_player = function(player)
    player.task1 = player.task1 or {}
    local task1 = player.task1
    task_mgr.init_task(player, task1, task_cfg)
end

M.trigger_event = function(player, pevent)
    task_mgr.count_task(player, player.task1, task_cfg, pevent)
end

task_mgr.add_taskmgr("task1", M)
mgrs.add_mgr("task1", M)
return M
