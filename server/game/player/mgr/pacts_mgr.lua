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

local handle_opens = function(opens)
    if not opens or not next(opens) then
        return
    end

    for _, actid in ipairs(opens) do
        local func = get_impl_func(actid, "open")
        if not func then
            goto cont
        end
        for playerid, player in pairs(players) do
            func(player)
        end
        ::cont::
    end
end

local handle_closes = function(closes)
    if not closes or not next(closes) then
        return
    end

    for _, actid in ipairs(closes) do
        local func = get_impl_func(actid, "close")
        if not func then
            goto cont
        end
        for playerid, player in pairs(players) do
            func(player)
        end
        ::cont::
    end
end

M.activities_info = function(info, opens, closes)
    data.activities = info
    activities = info
    -- print("recv activities info", dump(info))
    -- print("activities open", opens and dump(opens))

    if opens then
        handle_opens(opens)
    end
    if closes then
        handle_closes(closes)
    end
end

M.isopen = function(actid)
    local act = activities[actid]
    if not act then
        return
    end
    return act.isopen
end

M.check = function(player, actid, obj)
    if not M.isopen(actid) then
        if obj.isopen then
            local func = get_impl_func(actid, "close")
            if func then
                func(player)
            end
            return
        end
    else
        local act = activities[actid]
        if not obj.isopen then
            obj.isopen = true
            obj.starttm = act.starttm
            local func = get_impl_func(actid, "open")
            if func then
                func(player)
            end
            return
        end
        if obj.isopen and obj.starttm ~= act.starttm then
            local closefunc = get_impl_func(actid, "close")
            if closefunc then
                closefunc(player)
            end
            obj.isopen = true
            obj.starttm = act.starttm
            local openfunc = get_impl_func(actid, "open")
            if openfunc then
                openfunc(player)
            end
        end
    end
end

return M
