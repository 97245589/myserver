require "common.tool.lua_tool"
local require, string, tostring = require, string, tostring
local print, dump = print, dump
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local socket = require "skynet.socket"

local config_load = require "common.service.config_load"
local proto = config_load.proto()
local host = proto.host
local request = proto.push_req

local acc, local_server, login_host, game_host, gameid
local session = 1
local fd, game_key, send_request, recv_data

local conn_to_login = function()
    fd = socket.open(login_host)
    -- print("conn to login server", fd)

    local cpri = crypt.randomkey()
    local cpub = crypt.dhexchange(cpri)

    send_request("exchange", {
        cpub = cpub
    })
    local _, _, res = recv_data()
    local spub = res.spub
    print("exchange key ======", #spub)

    game_key = crypt.dhsecret(spub, cpri)

    local v = tostring(skynet.time())
    send_request("login_verify", {
        verify = {v, crypt.desencode(game_key, v)}
    })
    recv_data()
    print("verify success ======")

    send_request("choose_gameserver", {
        acc = acc,
        server = gameid
    })
    local _, _, res = recv_data()
    game_host = res.host
    print("choose gameserver success get host:", game_host)
    socket.close(fd)
end

local conn_to_game = function()
    fd = socket.open(game_host)
end

local send_package = function(fd, pack)
    local package = string.pack(">s2", pack)
    socket.write(fd, package)
end

recv_data = function()
    local len
    len = socket.read(fd, 2)
    len = len:byte(1) * 256 + len:byte(2)
    local msg = socket.read(fd, len)
    return host:dispatch(msg)
end

send_request = function(name, args)
    session = session + 1
    local str = request(name, args, session)
    send_package(fd, str)
    return name, session
end

local client_start = function()
    if local_server then
        conn_to_game()
        send_request("verify", {
            acc = acc
        })
        recv_data()
    else
        conn_to_login()
        conn_to_game()
        local v = crypt.randomkey()
        send_request("verify", {
            acc = acc,
            verify = {v, crypt.desencode(game_key, v)}
        })
        recv_data()
    end
end

return {
    client_start = function(args)
        acc = args.acc or "1993"
        local_server = args.local_server
        login_host = args.login_host or "0.0.0.0:10301"
        game_host = args.game_host or "0.0.0.0:10101"
        gameid = gameid or "1"
        client_start()
    end,
    send_request = send_request,
    recv_data = recv_data
}
