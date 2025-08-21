local require, os = require, os
local skynet = require "skynet"
local mgrs = require "server.game.player.mgrs"
local push = require"server.game.player.client_req".push

local M = {}

M.init_player = function(player)
    if not player.role then
        player.role = {}
    end
    local role = player.role
end

M.tick_player = function(player)
    push(player.playerid, "push_test", {
        test = skynet.now()
    })
end

M.tick = function()
end

mgrs.add_mgr("role", M)
return M
