local require, print, os, pairs = require, print, os, pairs
require "common.tool.lua_tool"
local dump = dump
local skynet = require "skynet"
local config = require "common.service.service_config"

local cluster_node
local cluster_heartbeats = {}

local cmds = {}
cmds.heartbeat = function(cluster_name, cluster_host)
    cluster_node[cluster_name] = cluster_host
    cluster_heartbeats[cluster_name] = skynet.now()
    return cluster_node
end

local dispatch = function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local func = cmds[cmd]
        if func then
            skynet.ret(skynet.pack(func(...)))
        else
            skynet.response()(false)
            print("center cmd err", cmd, ...)
        end
    end)
end

local check_heartbeat = function()
    local tmout = 5 * 100
    while true do
        skynet.sleep(100)
        for cluster_name, tm in pairs(cluster_heartbeats) do
            if skynet.now() > tm + tmout then
                cluster_heartbeats[cluster_name] = nil
                cluster_node[cluster_name] = nil
            end
        end
        print(skynet.now(), "cluster_node", dump(cluster_node))
    end
end

skynet.start(function()
    local M = require "common.service.cluster_start"
    cluster_node = M.get_cluster_node()

    dispatch()
    skynet.fork(check_heartbeat)
end)
