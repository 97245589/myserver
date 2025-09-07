local require, print, dump = require, print, dump
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local mapaddrs

local M = {}

M.set_mapaddrs = function(addrs)
    -- print("get mapaddrs", dump(addrs))
    mapaddrs = addrs
end

local player_map_addr = function(player)
    local default_addr = mapaddrs.server.game
    local role = player.role
    if not role.mapaddr then
        return default_addr
    end
    if not role.cross then
        return mapaddrs.server[role.mapaddr] or default_addr
    else
        return role.mapaddr, role.cross
    end
end

M.send = function(player, cmd, ...)
    local mapaddr, cross = player_map_addr(player)
    if cross then
        cluster.send(cross, "@" .. cross, cmd, ...)
    else
        skynet.send(mapaddr, "lua", cmd, ...)
    end
end

M.call = function(player, cmd, ...)
    local mapaddr, cross = player_map_addr(player)
    if cross then
        return cluster.call(cross, "@" .. cross, cmd, ...)
    else
        return skynet.call(mapaddr, "lua", cmd, ...)
    end
end

return M
