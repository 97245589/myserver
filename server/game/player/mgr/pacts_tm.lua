local require, print, dump, os = require, print, tdump, os
local next, ipairs, pairs = next, ipairs, pairs
local mgrs = require "server.game.player.mgrs"
local players = require"server.game.player.players".players
local timefunc = require "common.func.timefunc"

local phandle = timefunc.player()

local data = mgrs.data
local acts_tm = data.acts_tm

local M = {
    impls = {}
}

local cb = function(id, tp, player, pobj)
    local impl = M.impls[id]
    if not impl then
        return
    end
    local func = impl[tp]
    if not func then
        return
    end
    func(player, pobj.id)
end

M.acts_tm = function(info, opens, closes)
    data.activities = info
    acts_tm = info

    if opens then
        phandle.handle_opens(players, "acts_tm", opens, acts_tm, cb)
    end
    if closes then
        phandle.handle_closes(players, "acts_tm", closes, acts_tm, cb)
    end

    -- print("recv acts_tm info", dump(info))
    -- if opens then
    --     print("acts_tm open", dump(opens))
    -- end
    -- if closes then
    --     print("acts_tm close", dump(closes))
    -- end
end

M.check_acts_tm = function(player)
    phandle.check(player, player.acts_tm, acts_tm, cb)
end

return M
