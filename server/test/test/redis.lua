require "common.tool.lua_tool"
local require, print, dump = require, print, dump
local math, string = math, string
local skynet = require "skynet"

local format = string.format

local cmd = function()
    local redis = require "common.tool.redis"
    local call = redis.call

    call("hmset", 1, 2, 20, 3, 30)
    call("hset", 1, 4, 40)
    print("hgetall", dump(call("hgetall", 1)))
    print("hmget", dump(call("hmget", 1, 2)))
    print(call("hget", 1, 3))
    call("hdel", 1, 2)
    print("hgetall", dump(call("hgetall", 1)))
    print("keys", dump(call("keys", "*")))
    call("del", 1)
    print("keys", dump(call("keys", "*")))
    call("flushdb")
end

local stress1 = function()
    local redis = require "common.tool.redis"
    local test = function(name)
        local t = skynet.now()
        local n = 20000
        for i = 1, n do
            redis.call("hget", i, 1)
        end
        print(format("%s hget %s times cost %s", name, n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(test, i)
    end
end

local stress2 = function()
    local redis = require "common.tool.redis"
    local zstd = require "common.tool.zstd"
    local call = redis.call

    local arr = {}
    for i = 1, 10000 do
        arr["pl:" .. i] = {
            id = i,
            level = math.random(200),
            photoid = math.random(10000)
        }
    end
    local bin = zstd.pack(arr)
    print(#bin, #skynet.packstring(arr))

    local test = function(idx, name)
        local t = skynet.now()
        local n = 1000
        for i = 1, n do
            call("hmset", idx * n + i, "data", bin)
        end
        print(format("%s %s: %s times cost %s", name, idx, n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(test, i, "redis")
    end
end

skynet.start(function()
    -- cmd()
    stress1()
    -- stress2()
end)
