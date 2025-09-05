local require, pairs, print, SERVICE_NAME = require, pairs, print, SERVICE_NAME

local skynet = require "skynet"
local profile = require "skynet.profile"
local profile_info = require "common.service.profile"

local M = {}
local mgrs = {}

local ticks = {}
local tick_players = {}
local init_players = {}
local after_init_players = {}

M.add_mgr = function(name, mgr)
    if mgrs[name] then
        print(SERVICE_NAME, "mgr name repeated", name)
    end
    mgrs[name] = mgr
    if mgr.tick then
        ticks[name] = mgr.tick
    end
    if mgr.tick_player then
        tick_players[name] = mgr.tick_player
    end
    if mgr.init_player then
        init_players[name] = mgr.init_player
    end
    if mgr.after_init_player then
        after_init_players[name] = mgr.after_init_player
    end
end

M.dump = function()
    return {
        -- mgrs = mgrs,
        ticks = ticks,
        tick_players = tick_players,
        init_players = init_players,
        after_init_players = after_init_players
    }
end

M.get_mgr = function(name)
    return mgrs[name]
end

M.all_tick = function()
    for name, func in pairs(ticks) do
        profile.start()

        func()

        local time = profile.stop()
        local cmd_name = "tick.." .. name
        profile_info.add_cmd_profile(cmd_name, time)
    end
end

M.all_tick_player = function(player)
    for name, func in pairs(tick_players) do
        profile.start()

        func(player)

        local time = profile.stop()
        local cmd_name = "tickplayer.." .. name
        profile_info.add_cmd_profile(cmd_name, time)
    end
end

M.all_init_player = function(player)
    for name, func in pairs(init_players) do
        func(player)
    end

    for name, func in pairs(after_init_players) do
        func(player)
    end
end

M.clear = function()
    mgrs = {}
    ticks = {}
    tick_players = {}
    init_players = {}
    after_init_players = {}
end

M.data = {}

return M
