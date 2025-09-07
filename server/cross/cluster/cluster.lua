local require, print, dump = require, print, dump
local pairs = pairs
local string = string
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local cluster_start = require "common.service.cluster_start"
local cmds = require "common.service.cmds"

local cluster_name = skynet.getenv("server_name") .. skynet.getenv("server_id")
local mapaddrs

cmds.set_mapaddrs = function(addrs)
    mapaddrs = addrs
end

cluster_start.set_diff_func(function(diff)
    local adds = diff.adds
    if not adds then
        return
    end
    for servername, _ in pairs(adds) do
        local str = string.sub(servername, 1, 4)
        if str ~= "game" then
            goto cont
        end

        cluster.send(servername, "@" .. servername, "set_mapaddrs", cluster_name, mapaddrs)
        print("send to", cluster_name, servername, dump(mapaddrs))
        ::cont::
    end
end)
