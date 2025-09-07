local require = require
local print, dump = print, tdump
local pacts_tm = require "server.game.player.mgr.pacts_tm"
local mgrs = require "server.game.player.mgrs"
local impls = pacts_tm.impls

local M = {}

M.init_player = function(player)
    player.acts_tm = player.acts_tm or {}
    pacts_tm.check_acts_tm(player)
end

impls[10] = {
    open = function(player, actid)
        -- print("player act open", actid)
    end,
    close = function(player, actid)
        -- print("player act close", actid)
    end
}

mgrs.add_mgr("pacts", M)
return M
