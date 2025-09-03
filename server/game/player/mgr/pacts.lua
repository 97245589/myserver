local require = require
local print, dump = print, tdump
local pacts_mgr = require "server.game.player.mgr.pacts_mgr"
local mgrs = require "server.game.player.mgrs"
local impls = pacts_mgr.impls

local M = {}

M.init_player = function(player)
    player.activities = player.activities or {}
    player.activities_data = player.activities_data or {}

    pacts_mgr.check_activities(player)
end

impls[10] = {
    open = function(player, pact)
        print("player act open", dump(pact))
    end,
    close = function(player, pact)
        print("player act close", dump(pact))
    end
}

mgrs.add_mgr("pacts", M)
return M
