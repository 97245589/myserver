local db = require "common.tool.leveldb"
local zstd = require "common.tool.zstd"

local prefix = "pl:"

local M = {}

M.get_player = function(playerid)
    return {}
    --[[
    local bin = db.call("hget", prefix .. playerid, "data")
    if not bin then
        return
    end
    return zstd.unpack(bin)
    ]]
end

M.save_player = function(playerid, player)
    -- local bin = zstd.pack(player)
    -- db.send("hset", prefix .. playerid, "data", bin)
end

return M
