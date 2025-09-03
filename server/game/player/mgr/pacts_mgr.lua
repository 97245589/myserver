local require, print, dump = require, print, tdump
local next, ipairs, pairs = next, ipairs, pairs
local mgrs = require "server.game.player.mgrs"
local players = require"server.game.player.players".players

local data = mgrs.data
local activities = data.activities

local M = {
    impls = {}
}

local get_impl_func = function(actid, cbname)
    local impl = M.impls[actid]
    if not impl then
        return
    end
    local func = impl[cbname]
    if not func then
        return
    end
    return func
end

local handle_close = function(player, actid)
    local pacts = player.activities
    local pact = pacts[actid]
    pacts[actid] = nil
    if not pact or not pact.isopen then
        return
    end
    local func = get_impl_func(actid, "close")
    if func then
        func(player, pact)
    end
end

local handle_open = function(player, actid, starttm)
    local act_open = function(pact)
        pact.actid = actid
        pact.isopen = true
        pact.starttm = starttm
        local func = get_impl_func(actid, "open")
        if func then
            func(player, pact)
        end
    end

    local pacts = player.activities
    pacts[actid] = pacts[actid] or {}
    local pact = pacts[actid]

    if pact.isopen and pact.starttm == starttm then
        return
    end

    if not pact.isopen then
        act_open(pact)
        return
    end

    if pact.starttm ~= starttm then
        local func = get_impl_func(actid, "close")
        if func then
            func(player, pact)
        end
        act_open(pact)
    end
end
local handle_opens = function(opens)
    for _, actid in ipairs(opens) do
        local starttm = activities[actid].starttm
        for playerid, player in pairs(players) do
            handle_open(player, actid, starttm)
        end
    end
end

local handle_closes = function(closes)
    for _, actid in ipairs(closes) do
        for playerid, player in pairs(players) do
            handle_close(player, actid)
        end
    end
end

M.activities_info = function(info, opens, closes)
    data.activities = info
    activities = info

    if opens then
        handle_opens(opens)
    end
    if closes then
        handle_closes(closes)
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
    for actid, act in pairs(activities) do
        if M.isopen(actid) then
            handle_open(player, actid, act.starttm)
        else
            handle_close(player, actid)
        end
    end

    for actid, pact in pairs(player.activities) do
        if not activities[actid] then
            handle_close(player, actid)
        end
    end
end

return M
