require "common.tool.lua_tool"
local require, math, tostring = require, math, tostring
local collectgarbage = collectgarbage
local print, dump = print, dump
local skynet = require "skynet"
local format = string.format
local random = math.random

local lru = function()
    print("====== lru test")
    local llru = require "lutil.lru"

    local func = function()
        local core = llru.create_lru(5)
        local data = {}
        for i = 1, 20 do
            local updatekey = tostring(random(10))
            print(updatekey)
            data[updatekey] = 1
            local evict = core:update(updatekey)
            if evict then
                data[evict] = nil
            end
        end
        print("data", dump(data))
    end

    local stress = function()
        local core = llru.create_lru(1000)
        local n = 1000000
        local t = skynet.now()
        for i = 1, n do
            local updatekey = tostring(random(2000))
            core:update(updatekey)
        end
        print(format("lru %s update times cost %s", n, skynet.now() - t))
    end

    func()
    stress()
    collectgarbage("collect")
end

local rank = function()
    print("=========== rank test")
    local lrank = require "lutil.rank"

    local func = function()
        local core = lrank.create_rank(5)
        for i = 1, 20 do
            local id = tostring(random(10))
            local score = random(100)
            print(format("id: %s, score: %s", id, score))
            core:add(id, score, i)
        end
        print("rank info:", dump(core:info()))
    end

    local stress = function()
        local core = lrank.create_rank(1000)
        local n = 1000000
        local t = skynet.now()
        for i = 1, n do
            core:add(tostring(random(2000)), random(100000), i)
        end
        print(format("rank add %s times cost %s", n, skynet.now() - t))

        local n = 10000
        local t = skynet.now()
        local ret
        for i = 1, n do
            ret = core:info()
        end
        print(format("rank info %s times cost %s", n, skynet.now() - t))
    end
    func()
    stress()
    collectgarbage("collect")
end

skynet.start(function()
    lru()
    rank()
end)
