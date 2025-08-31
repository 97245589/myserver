require "common.tool.lua_tool"
local require = require
local skynet = require "skynet"

local format = string.format

local cmd = function()
    local redis = require "common.tool.redis"
    local call = redis.call

    call("set", "hello", "world")
    print(call("get", "hello"))

    call("hmset", 1, "hello", "world", "haha", "heihei")
    print(dump(call("hgetall", 1)))
    print(dump(call("hmget", 1, "test", "hello", "haha")))

    local test = function(idx)
        local t = skynet.now()
        local n = 10000
        for i = 1, n do
            call("hmset", "hello" .. idx * n + 1, "test", "test1")
        end
        print(format("%s: hmset %s times cost %s", idx, n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(test, i)
    end
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
    local test = function(idx, name)
        local n = 1000
        for i = 1, n do
            call("hmset", idx * n + i, "data", bin)
        end
        print(format("%s %s: %s times cost %s", name, idx, n, skynet.now() - t))
    end

    for i = 1, 5 do
        skynet.fork(test, i, "redis")
    end
    skynet.sleep(200)

    call = require"common.tool.leveldb".call
    for i = 1, 5 do
        skynet.fork(test, i, "leveldb")
    end
end

skynet.start(function()
    -- cmd()
    stress()
end)
