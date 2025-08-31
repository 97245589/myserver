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

    local handle = {
        hgetall = function(key, parr, rarr)
            local ret = {}
            for i = 1, #rarr, 2 do
                ret[rarr[i]] = rarr[i + 1]
            end
            return ret

        end,
        hmget = function(key, parr, rarr)
            local ret = {}
            for i = 1, #parr do
                ret[parr[i]] = rarr[i]
            end
            return ret
        end
    }

    local dbcall = function(cmd, key, ...)
        local ret = skynet.call(addr, "lua", cmd, key, ...)
        local func = handle[cmd]
        if not func then
            return ret
        end

        local parr = table.pack(...)
        return func(key, parr, ret)
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
