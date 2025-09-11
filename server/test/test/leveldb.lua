require "common.tool.lua_tool"
local require, print, dump = require, print, dump
local string, math = string, math
local skynet = require "skynet"
local format = string.format

local test = function()
    local leveldb = require "common.tool.leveldb"
    local call = leveldb.call

    call("hmset", 1, 2, 20, 3, 30, 7, 70)
    call("hset", 1, 4, 40)
    print("hgetall", dump(call("hgetall", 1)))
    print("hmget", dump(call("hmget", 1, 2)))
    print(call("hget", 1, 3))
    call("hdel", 1, 2)
    print("hgetall", dump(call("hgetall", 1)))
    call("hmset", 10, 1, 1)
    print("keys", dump(call("keys", "*")))
    print("realkeys", dump(call("realkeys")))
    call("del", 1)
    print("keys", dump(call("keys", "*")))

    for i = 1, 100 do
        call("hset", i, "hello", "world")
    end
    print(dump(call("keys", "2*")))
end

local stress1 = function()
    local leveldb = require "common.tool.leveldb"
    local call = leveldb.call

    local t = skynet.now()
    local n = 100000
    for i = 1, n do
        call("hset", i, "hello" .. i, "world" .. i)
    end
    print(format("hset %s times cost %s", n, skynet.now() - t))
    print(dump(call("hgetall", 100000)))

    local t = skynet.now()
    for i = 1, n do
        call("hgetall", i)
    end
    print(format("hgetall %s times cost %s", n, skynet.now() - t))
end

local stress2 = function()
    local leveldb = require "common.tool.leveldb"
    local call = leveldb.call

    local str = ""
    for i = 1, 10000 do
        str = str .. "1234567890"
    end
    print(#str)

    local t = skynet.now()
    local n = 3000
    for i = 1, n do
        call("hset", i, "data", str)
    end
    print(format("hset %s times cost %s", n, skynet.now() - t))
    print(#call("hget", 3000, "data"))

    local t = skynet.now()
    for i = 1, n do
        call("hget", i, "data")
    end
    print(format("hget %s times cost %s", n, skynet.now() - t))
end

skynet.start(function()
    -- test()
    stress1()
    stress2()
end)
