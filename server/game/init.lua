local require, print, table, pairs = require, print, table, pairs
local tonumber = tonumber
require "common.tool.lua_tool"

local skynet = require "skynet"
local socket = require "skynet.socket"
require "skynet.manager"
local env = require "common.func.env"
local gamecommon = require "server.game.game_common"

skynet.register("game_init")

local services = {}
local cmds = {}

local init_services = function()
    for i = 1, gamecommon.player_service_num do
        local service_name = "player" .. i
        local addr = skynet.newservice("server/game/player/start", service_name, 1)
        services[service_name] = addr
    end

    local addr = skynet.newservice("server/game/game/start", "game", 1)
    services.game = addr

    skynet.newservice("server/game/mapmgr/start", "mapmgr", 1)
    skynet.newservice("server/game/watchdog/start", "watchdog")
    skynet.newservice("server/game/verify/start", "verify")

    if not env.local_server() then
        skynet.timeout(100, function()
            skynet.newservice("server/game/cluster/start", "cluser")
        end)
    end
end

local init_rpc = function()
    cmds.reload = function()
        for name, addr in pairs(services) do
            skynet.send(addr, "lua", "hotreload")
        end
    end

    skynet.dispatch(function(_, _, cmd, ...)
        local func = cmds[cmd]
        if func then
            skynet.retpack(func(...))
        else
            skynet.response()(false)
        end
    end)
end

local console_init = function()
    if env.daemon() then
        return
    end

    skynet.fork(function()
        local stdin = socket.stdin()
        local split = split
        while true do
            local cmdline = socket.readline(stdin, "\n")
            local arr = split(cmdline, " ")
            local cmd, p1, p2 = table.unpack(arr)
            local func = cmds[cmd]
            if func then
                func(p1, p2)
            end
        end
    end)
end

skynet.start(function()
    init_services()
    init_rpc()
    console_init()
end)
