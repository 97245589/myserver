local mode = ...

require "common.tool.lua_tool"
local require, print = require, print
local skynet = require "skynet"
local format = string.format

if mode == "child" then
    require "skynet.manager"
    skynet.register("test")
    skynet.start(function()
        local i = 0
        skynet.dispatch("lua", function()
            skynet.retpack("success" .. i)
            i = i + 1
        end)
    end)
else
    local addr

    local calltest = function()
        print("calltest ==========")
        local test = function(name, n)
            for i = 1, n do
                local ret = skynet.call(addr, "lua", "hello")
                print(name, ret)
            end
        end
        skynet.fork(test, 1, 5)
        skynet.fork(test, 2, 5)
        skynet.sleep(10)
    end

    local test = function()
        local n = 1e5
        local t = skynet.now()
        for i = 1, n do
            local ret = skynet.call(addr, "lua", "hello")
        end
        print(format("skynet call %s times cost: %s", n, skynet.now() - t))

        t = skynet.now()
        for i = 1, n do
            local ret = skynet.call("test", "lua", "hello")
        end
        print(format("skynet name call %s times cost: %s", n, skynet.now() - t))
    end

    skynet.start(function()
        addr = skynet.newservice("server/test/test/rpc", "child")
        calltest()
        test()
        skynet.exit()
    end)
end
