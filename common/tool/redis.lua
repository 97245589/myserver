require "common.tool.lua_tool"
local require, print = require, print
local skynet = require "skynet"

local mode = ...

if mode == "child" then
    skynet.start(function()
        local redis = require "skynet.db.redis"
        local db = redis.connect({
            host = "0.0.0.0",
            port = 6379
        })
        skynet.dispatch("lua", function(_, _, cmd, ...)
            skynet.retpack(db[cmd](db, ...))
        end)
    end)
else
    local table = table
    local addr = skynet.uniqueservice("common/tool/redis", "child")

    local dbsend = function(...)
        skynet.send(addr, "lua", ...)
    end

    local dbcall = function(cmd, key, ...)
        return skynet.call(addr, "lua", cmd, key, ...)
    end

    return {
        send = dbsend,
        call = dbcall
    }
end
