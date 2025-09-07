local require, print, dump = require, print, dump
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local crypt = require "skynet.crypt"
local cmds = require "common.service.cmds"

local game_servers = {}
local acc_serverid = {}

cmds.game_servers = function(args)
    game_servers = args
    -- print("game_servers update", dump(args))
end
cmds.login_req = function(acc, server, secret)
    local game_server = game_servers[server]
    if not game_server then
        return
    end

    local serverid = acc_serverid[acc]
    if serverid and serverid ~= server then
        local dest = "game" .. serverid
        cluster.send(dest, "verify", "login_kick", acc)
    end
    acc_serverid[acc] = server

    local dest = "game" .. server
    cluster.call(dest, "verify", "set_loginkey", acc, secret)
    return {
        code = 0,
        host = game_server.host
    }
end
