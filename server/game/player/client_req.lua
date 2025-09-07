local require, string, os, error = require, string, os, error
local print, split, tonumber, format = print, split, tonumber, string.format

local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local profile = require "skynet.profile"
local profile_info = require "common.service.profile"
local players = require "server.game.player.players"
local game_common = require "server.game.game_common"
local map = require "server.game.player.map"

local proto
local host
local push_req
local SERVICE_NAME = SERVICE_NAME

local M = {}
M.client_req = {}

M.load_proto = function()
    local config_load = require "common.service.config_load"
    proto = config_load.proto()
    host = proto.host
    push_req = proto.push_req
end
M.load_proto()

local fd_playerid = {}
local playerid_fd = {}

local send_package = function(fd, pack)
    local ret = socket.write(fd, string.pack(">s2", pack))
    if not ret then
        local playerid = fd_playerid[fd]
        M.kick_player(playerid)
        fd_playerid[fd] = nil
    end
end

M.kick_player = function(playerid)
    if not playerid then
        return
    end
    local fd = playerid_fd[playerid]
    if fd then
        fd_playerid[fd] = nil
        skynet.send("watchdog", "lua", "close_conn", fd)
        local player = players.players[playerid]
        if player then
            map.send(player, "player_leave", player.playerid)
        end
    end
    playerid_fd[playerid] = nil
end

M.player_enter = function(playerid, fd, gate, acc)
    M.kick_player(playerid)
    skynet.send(gate, "lua", "forward", fd)
    fd_playerid[fd] = playerid
    playerid_fd[playerid] = fd
    local player = players.get_player(playerid)
    player.acc = acc
    -- print(format("playerenter fd:%s playerid: %s", fd, playerid), player)
end

M.push = function(playerid, name, args)
    local fd = playerid_fd[playerid]
    if not fd then
        return
    end
    local str = push_req(name, args, 0)
    send_package(fd, str)
end

local request = function(fd, cmd, args, res)
    local playerid = fd_playerid[fd]
    if not playerid then
        return skynet.send("watchdog", "lua", "close_conn", fd)
    end
    local player = players.get_player(playerid)
    local cli_func = M.client_req[cmd]
    local ret = cli_func(player, args) or {
        code = -1
    }
    return res(ret)
end

skynet.register_protocol({
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        return host:dispatch(msg, sz)
    end,
    dispatch = function(fd, _, type, cmd, ...)
        skynet.ignoreret()
        profile.start()

        send_package(fd, request(fd, cmd, ...))

        local time = profile.stop()
        local cmd_name = "clireq.." .. cmd
        profile_info.add_cmd_profile(cmd_name, time)
    end
})

return M
