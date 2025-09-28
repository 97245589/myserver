local require, print, dump = require, print, dump
local skynet = require "skynet"

local server_name = skynet.getenv("server_name")
local server_id = skynet.getenv("server_id")
local cluster_name = server_name .. server_id

local host = skynet.getenv("ip") .. ":" .. skynet.getenv("cluster_port")

local local_server = skynet.getenv("local_server")
if local_server == "nil" or local_server == "false" then
    local_server = nil
end

local daemon = skynet.getenv("daemon")

local gate_port = skynet.getenv("gate_port")

local game_outer_host
local M = {}

M.game_outer_host = function()
    game_outer_host = game_outer_host or skynet.getenv("outer_ip") .. ":" .. gate_port
    return game_outer_host
end

M.gate_port = function()
    return gate_port
end

M.server_name = function()
    return server_name
end

M.server_id = function()
    return server_id
end

M.clusetr_name = function()
    return cluster_name
end

M.host = function()
    return host
end

M.server_name = function()
    return server_name
end

M.local_server = function()
    return local_server
end

M.daemon = function()
    return daemon
end

return M
