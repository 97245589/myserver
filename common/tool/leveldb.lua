require "common.tool.lua_tool"
local require, print, string = require, print, string
local table, next = table, next
local skynet = require "skynet"

local mode = ...
local SPLIT_CHAR = string.char(0xff)

if mode == "child" then
    local leveldb = require "lleveldb"
    local db = leveldb.create_lleveldb("db", 5 * 1024 * 1024)

    local cmds = {
        hmset = function(arr)
            db:hmset(arr)
        end,
        hgetall = function(key)
            local tb = db:hgetall(key)
            return next(tb) and tb
        end,
        keys = function()
            local tb = db:keys()
            return next(tb) and tb
        end,
        del = function(key)
            db:del(key)
        end,
        realkeys = function()
            local tb = db:realkeys()
            return next(tb) and tb
        end
    }

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local func = cmds[cmd]
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
        del = function(key)
            send("del", key)
        end,
        keys = function()
            return call("keys")
        end,
        hgetall = function(key)
            return call("hgetall", key)
        end,
        hmset = function(key, ...)
            local arr = table.pack(...)
            for i = 1, #arr, 2 do
                arr[i] = key .. SPLIT_CHAR .. arr[i]
            end
            call("hmset", arr)
        end,
        real_keys = function()
            return call("realkeys")
        end
    }
end
