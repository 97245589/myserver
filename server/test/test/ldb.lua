require "common.tool.lua_tool"
local skynet = require "skynet"

local format = string.format

local test = function()
    local db = require "common.tool.leveldb"
    local call = db.call
    local send = db.send

    call("hmset", "hello", 1, "hello1", 2, "world1", 3, "ttt")
    call("hmset", "test", "test1", "test2")
    print(dump(call("hgetall", "hello")))
    print(dump(call("keys")))
    call("hdel", "hello", 2)
    print(dump(call("hgetall", "hello")))
    call("del", "hello")
    print(dump(call("hgetall", "hello")))
    print(dump(call("hgetall", "test")))
    print(#db.real_keys())
    call("del", "test")
end

skynet.start(function()
    test()
end)
