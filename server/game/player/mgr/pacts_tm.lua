local require, print, dump, os = require, print, tdump, os
local next, ipairs, pairs = next, ipairs, pairs
local players = require"server.game.player.players".players
local timefunc = require "common.func.timefunc"
local skynet = require "skynet"

local acts_tm = skynet.call("player_mgr", "lua", "get_acts_tm")

local phandle = timefunc.player()

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

M.acts_tm_notify = function(info, opens, closes)
    acts_tm = info

    if opens then
        phandle.handle_opens(players, "acts_tm", opens, acts_tm, cb)
    end
    if closes then
        phandle.handle_closes(players, "acts_tm", closes, acts_tm, cb)
    end

    --[[
    print("recv acts_tm info", dump(info))
    if opens then
        print("acts_tm open", dump(opens))
    end
    if closes then
        print("acts_tm close", dump(closes))
    end
    ]]
end

M.get_actstm = function()
    return acts_tm
end

M.check_acts_tm = function(player)
    phandle.check(player, player.acts_tm, acts_tm, cb)
end

return M
