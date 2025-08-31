require "common.tool.lua_tool"
local skynet = require "skynet"

local format = string.format

local test = function()
    local db = require "common.tool.leveldb"
    local call = db.call
    local send = db.send

    call("hmset", "hello", 1, "hello1", 2, "world1", 3, "ttt")
    call("hmset", "test", "test1", "test2")
    print("hmget", dump(call("hmget", "hello", 1, "test1", 3)))
    print("hmget", dump(call("hmget", "test", 1, "test1", 3)))
    print(dump(call("hgetall", "hello")))
    print(dump(call("keys")))
    call("hdel", "hello", 2)
    print(dump(call("hgetall", "hello")))
    call("del", "hello")
    print(dump(call("hgetall", "hello")))
    print(dump(call("hmget", "hello", 1)))
    print(dump(call("hgetall", "test")))
    print(#db.real_keys())
    call("del", "test")
end

local press = function()
    local db = require "common.tool.leveldb"
    local call = db.call

    local t = skynet.now()
    local n = 100000
    for i = 1, n do
        call("hmset", i, "hello" .. i, "world" .. i)
    end
    print(format("hmset %s times cost %s", n, skynet.now() - t))

    local t = skynet.now()
    for i = 1, n do
        call("hgetall", i)
    end
    print(format("hgetall %s times cost %s", n, skynet.now() - t))
end

skynet.start(function()
    -- test()
    press()
end)
