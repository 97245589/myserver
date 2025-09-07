local require, print, dump = require, print, dump
local pairs = pairs
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local cluster_name = skynet.getenv("server_name") .. skynet.getenv("server_id")
local mapaddrs = {}

skynet.fork(function()
    while true do
        skynet.sleep(1000)
        local cluster_node = skynet.call("cluster", "lua", "all_cluster_node")
        for clustername, _ in pairs(mapaddrs) do
            if cluster_name == "addrs" then
                goto cont
            end
            if not cluster_node[cluster_name] then
                mapaddrs[cluster_name] = nil
            end
            ::cont::
        end
    end
end)

local M = {}

M.set_mapaddrs = function(src, addrs)
    if cluster_name == src then
        mapaddrs.addrs = addrs
    else
        mapaddrs[src] = addrs
    end
    print("get mapaddrs", src, dump(mapaddrs))
end

local player_map_addr = function(player)
    local default_addr = mapaddrs.addrs.game
    local role = player.role
    if not role.mapaddr then
        return default_addr
    end
    if not role.cross then
        return mapaddrs.addrs[role.mapaddr] or default_addr
    else
        if not mapaddrs[role.cross] then
            return default_addr
        end
        return role.mapaddr, role.cross
    end
end

M.send = function(player, cmd, ...)
    local mapaddr, cross = player_map_addr(player)
    if cross then
        cluster.send(cross, "@" .. cross, cmd, mapaddr, ...)
    else
        skynet.send(mapaddr, "lua", cmd, ...)
    end
end

M.call = function(player, cmd, ...)
    local mapaddr, cross = player_map_addr(player)
    if cross then
        return cluster.call(cross, "@" .. cross, cmd, mapaddr, ...)
    else
        return skynet.call(mapaddr, "lua", cmd, ...)
    end
end

return M
