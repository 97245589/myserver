require "common.tool.lua_tool"
local skynet = require "skynet"

local format = string.format

local test = function()
    local db = require "common.tool.leveldb"
    local n = 100000
    local t

    t = skynet.now()
    for i = 1, n do
        db.hmset("hello" .. i, 1, "hello" .. i, 2, "world" .. i)
    end
    print(format("hmset %s times cost %s", n, skynet.now() - t))

    t = skynet.now()
    for i = 1, n do
        local ret = db.hgetall("hello" .. i)
    end
    print(format("hgetall %s times cost %s", n, skynet.now() - t))

    print(dump(db.hgetall("hello99999")))
    print(db.hgetall("hello0000"))
    print(#db.keys())
    print(#db.real_keys())

    db.del("hello111")
    db.del("hello")
    print(dump(db.hgetall("hello11")))
    print(db.hgetall("hello111"))
    print(#db.keys())
    print(#db.real_keys())
end

skynet.start(function()
    test()
end)
