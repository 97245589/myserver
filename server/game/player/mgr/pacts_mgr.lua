local require, print, dump, os = require, print, tdump, os
local next, ipairs, pairs = next, ipairs, pairs
local mgrs = require "server.game.player.mgrs"
local players = require"server.game.player.players".players
local timefunc = require "common.func.timefunc"

local phandle = timefunc.player()

local data = mgrs.data
local activities = data.activities

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
    func(player, pobj)
end

M.activities_info = function(info, opens, closes)
    data.activities = info
    activities = info

    if opens then
        phandle.handle_opens(players, "activities", opens, activities, cb)
    end
    if closes then
        phandle.handle_closes(players, "activities", closes, activities, cb)
    end

    --[[
    print("recv activities info", dump(info))
    if opens then
        print("activities open", dump(opens))
    end
    if closes then
        print("activities close", dump(closes))
    end
    ]]
end

M.check_activities = function(player)
    phandle.check(player, player.activities, activities, cb)
end

return M
