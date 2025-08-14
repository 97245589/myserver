require "common.tool.lua_tool"
local require, print, dump = require, print, dump
local skynet = require "skynet"
local profile = require "skynet.profile"
local squeue = require "skynet.queue"

local queue_test = function()
    print("cs test ============")
    local test = function(t)
        print("queue test", t)
        skynet.sleep(200)
    end

    skynet.fork(test)
    skynet.fork(test)

    local cs = squeue()
    cs(test, skynet.now())
    cs(test, skynet.now())
end

local time_test = function()
    print("time test ===========")
    print(skynet.now(), skynet.time(), os.time(), os.time({
        year = 2023,
        month = 10,
        day = 1
    }))
    print(dump(os.date("*t")), dump(os.date("!*t")))
    print(os.date("%Y-%m-%d %H:%M:%S"), os.date("!%Y-%m-%d %H:%M:%S"))
end

local profile_test = function()
    print("profile test ======")

    local time = 0

    local test = function()
        profile.start()
        local t = profile.stop()
        time = time + t
    end

    for i = 1, 1e6 do
        test()
    end
    print(time)
end

skynet.start(function()
    time_test()
    profile_test()
    queue_test()
end)
