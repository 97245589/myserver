local require = require
local task_mgr = require "server.game.player.mgr.task_mgr"
local enums = require "common.func.enums"
local role = require "server.game.player.mgr.role"

local handle = {
    [enums.task_player_level] = function(player, tevent, task)
        return player.role.level
    end
}

task_mgr.set_handle(handle)
