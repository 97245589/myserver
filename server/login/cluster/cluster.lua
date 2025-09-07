local require, print, dump = require, print, dump
local string, pairs, pcall = string, pairs, pcall
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local cluster_start = require "common.service.cluster_start"
local cmds = require "common.service.cmds"
local ssub = string.sub

local game_servers = {}

local send_gameservers = function()
    print("send_gameservers", dump(game_servers))
    skynet.send("info", "lua", "game_servers", game_servers)
end

cluster_start.set_diff_func(function(diff)
    local hadds = function(adds)
        if not adds then
            return
        end
        local m
        for servername, _ in pairs(adds) do
            local str = ssub(servername, 1, 4)
            if str ~= "game" then
                goto continue
            end
            if game_servers[ssub(servername, 5)] then
                goto continue
            end
            m = true
            local ok, ret = pcall(cluster.call, servername, "@" .. servername, "gameserver_info")
            if not ok then
                goto continue
            end
            game_servers[ret.serverid] = ret
            print("req gameserverinfo", servername, dump(ret))
            ::continue::
        end
        return m
    end

    local hdels = function(dels)
        if not dels then
            return
        end

        local m
        for servername, _ in pairs(dels) do
            local str = ssub(servername, 1, 4)
            if str ~= "game" then
                goto continue
            end
            local id = ssub(servername, 5)
            if game_servers[id] then
                game_servers[id] = nil
                m = true
            end
            ::continue::
        end
        return m
    end
    local m = hadds(diff.adds) or hdels(diff.dels)
    if m then
        send_gameservers()
    end
end)
