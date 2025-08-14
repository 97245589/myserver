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
    local addr = skynet.uniqueservice("common/service/db", "child")

    local dbsend = function(...)
        skynet.send(addr, "lua", ...)
    end

    local dbcall = function(...)
        return skynet.call(addr, "lua", ...)
    end

    local scan = function(match, count, func, maxlen)
        local len = 0
        local cursor = 0
        while true do
            local ret = dbcall("scan", cursor, "MATCH", match, "COUNT", count)
            cursor = ret[1]
            local arr = ret[2]
            if #arr > 0 then
                func(arr)
            end
            if "0" == cursor then
                return
            end
            len = len + #arr
            if maxlen and len >= maxlen then
                return
            end
        end
    end

    return {
        send = dbsend,
        call = dbcall,
        scan = scan
    }
end
