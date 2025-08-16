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
        hdel = function(arr)
            db:hdel(arr)
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

    local handle = {
        hmset = function(key, ...)
            local arr = table.pack(...)
            for i = 1, #arr, 2 do
                arr[i] = key .. SPLIT_CHAR .. arr[i]
            end
            return arr
        end,
        hdel = function(key, ...)
            local arr = table.pack(...)
            for i = 1, #arr do
                arr[i] = key .. SPLIT_CHAR .. arr[i]
            end
            return arr
        end
    }

    local send = function(cmd, ...)
        local func = handle[cmd]
        if not func then
            skynet.send(addr, "lua", cmd, ...)
        else
            skynet.send(addr, "lua", cmd, func(...))
        end
    end

    local call = function(cmd, ...)
        local func = handle[cmd]
        if not func then
            return skynet.call(addr, "lua", cmd, ...)
        else
            return skynet.call(addr, "lua", cmd, func(...))
        end
    end

    return {
        call = call,
        send = send,
        real_keys = function()
            return call("realkeys")
        end
    }
end
