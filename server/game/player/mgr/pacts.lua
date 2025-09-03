local print = print
local require = require
local pacts_mgr = require "server.game.player.mgr.pacts_mgr"
local mgrs = require "server.game.player.mgrs"
local impls = pacts_mgr.impls

local M = {}

M.init_player = function(player)
    player.act10 = player.act10 or {}
    pacts_mgr.check(player, 10, player.act10)

    player.act11 = player.act11 or {}
    pacts_mgr.check(player, 11, player.act11)
end

impls[10] = {
    open = function(player)
        print("act10 is open")
        local act10 = player.act10
    end,
    close = function(player)
        player.act10 = nil
    end
}

mgrs.add_mgr("pact10", M)
return M
