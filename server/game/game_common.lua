local require = require
local skynet = require "skynet"
local crc = require "skynet.db.redis.crc16"

local player_service_num = 2

local M = {
    player_service_num = player_service_num
}

local playerserviceid = function(playerid)
    return crc(playerid) % player_service_num + 1
end

M.send_player_service = function(cmd, playerid, ...)
    local player_service = playerserviceid(playerid)
    skynet.send("player" .. player_service, "lua", cmd, playerid, ...)
end

M.call_player_service = function(cmd, playerid, ...)
    local player_service = playerserviceid(playerid)
    return skynet.call("player" .. player_service, "lua", cmd, playerid, ...)
end

M.send_all_player_service = function(...)
    for i = 1, player_service_num do
        skynet.send("player" .. i, "lua", ...)
    end
end

M.get_player_service = function(playerid)
    return "player" .. playerserviceid(playerid)
end

return M
