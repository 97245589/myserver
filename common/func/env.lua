local require, print, dump = require, print, dump
local skynet = require "skynet"

local server_name
local server_id
local cluster_name
local host
local daemon
local gate_port
local game_outer_host

local local_server = skynet.getenv("local_server")
if local_server == "nil" or local_server == "false" then
    local_server = nil
end

local M = {}

M.game_outer_host = function()
    game_outer_host = game_outer_host or skynet.getenv("outer_ip") .. ":" .. gate_port
    return game_outer_host
end

M.gate_port = function()
    gate_port = gate_port or skynet.getenv("gate_port")
    return gate_port
end

M.server_name = function()
    server_name = server_name or skynet.getenv("server_name")
    return server_name
end

M.server_id = function()
    server_id = server_id or skynet.getenv("server_id")
    return server_id
end

M.clusetr_name = function()
    cluster_name = cluster_name or M.server_name() .. M.server_id()
    return cluster_name
end

M.host = function()
    host = host or skynet.getenv("ip") .. ":" .. skynet.getenv("cluster_port")
    return host
end

M.local_server = function()
    return local_server
end

M.daemon = function()
    daemon = daemon or skynet.getenv("daemon")
    return daemon
end

return M
