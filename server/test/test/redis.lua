require "common.tool.lua_tool"
local require = require
local skynet = require "skynet"

local format = string.format

local test = function()
    local redis = require "common.tool.redis"
    local send = redis.send
    local call = redis.call

    for i = 1, 100 do
        call("set", "hello" .. i, "world" .. i)
    end
    print(call("get", "hello5"), call("get", "hello100"))

    local n = 10000
    local t = skynet.now()
    local get_test = function(m)
        for i = 1, n do
            local ret = call("get", "hello" .. i)
        end
        print(format("%s get %s times cost %s", m, n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(get_test, i)
    end
end

local test_scan = function()
    local redis = require "common.tool.redis"
    redis.scan("*", 10, function(arr)
        print("test all", #arr)
    end)

    redis.scan("*", 5, function(arr)
        print("test maxlen", #arr)
    end, 30)

    redis.scan("hello1*", 3, function(arr)
        print(dump(arr))
    end)
end

local stress = function()
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

    local t = skynet.now()
    local test = function(idx)
        local n = 1000
        for i = 1, n do
            call("set", idx * n + i, bin)
        end
        print(format("%s times cost %s", n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(test, i)
    end
end

skynet.start(function()
    test()
    test_scan()
    -- stress()
end)
