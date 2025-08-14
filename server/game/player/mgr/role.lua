local require, os = require, os
local mgrs = require "server.game.player.mgrs"

local M = {}

M.init_player = function(player)
    if not player.role then
        player.role = {}
    end
    local role = player.role
end

M.tick_player = function(player)
end

M.tick = function()
end

mgrs.add_mgr("role", M)
return M
