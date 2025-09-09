require "common.tool.lua_tool"
local require, print = require, print
local skynet = require "skynet"

local mode = ...

if mode == "child" then
    local table = table
    local lleveldb = require "lleveldb"
    local db = lleveldb.create("db")
    local CMD = {}
    CMD.realkeys = function()
        return db:realkeys()
    end
    CMD.del = function(key)
        db:del(key)
    end
    CMD.keys = function(p)
        return db:keys(p)
    end
    CMD.hdel = function(key, hkey)
        db:hdel(key, hkey)
    end
    CMD.hget = function(key, hkey)
        return db:hget(key, hkey)
    end
    CMD.hset = function(key, hkey, val)
        return db:hset(key, hkey, val)
    end
    CMD.hmset = function(key, ...)
        db:hmset(table.pack(key, ...))
    end
    CMD.hmget = function(key, ...)
        return db:hmget(table.pack(key, ...))
    end
    CMD.hgetall = function(key)
        return db:hgetall(key)
    end

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local func = CMD[cmd]
            if func then
                skynet.retpack(func(...))
            else
                skynet.response()(false)
            end
        end)
    end)
else
    local addr = skynet.uniqueservice("common/tool/leveldb", "child")

    local send = function(...)
        skynet.send(addr, "lua", ...)
    end

    local call = function(...)
        return skynet.call(addr, "lua", ...)
    end

    return {
        send = send,
        call = call
    }
end
