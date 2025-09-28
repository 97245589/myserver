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
        local core = llru.create(5)
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
        local core = llru.create(1000)
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

    local random_test = function()
        local rank = lrank.create(5)
        for i = 1, 20 do
            local id = tostring(random(10))
            local score = random(100)
            print(format("id: %s, score: %s", id, score))
            rank:add(id, score, i)
        end
        print("rank info:", dump(rank:info(1, 5)))
    end

    local test = function()
        local rank = lrank.create(10)
        for i = 1, 20 do
            rank:add(i % 10, i + 100, 0)
        end
        print("3rd to 7th", dump(rank:info(3, 7)))
        print("1st to 20th", dump(rank:info(1, 20)))
        print("getorder", rank:get_order(5), rank:get_order(20))
    end

    local stress = function()
        local rank = lrank.create(1000)

        local t = skynet.now()
        local n = 1000000
        for i = 1, n do
            rank:add(i % 2000, i, i)
        end
        print(format("%s times add cost %s", n, skynet.now() - t))

        local t = skynet.now()
        local info
        local n = 10000
        for i = 1, n do
            info = rank:info(1, 1000)
        end
        print("info len", #info)
        print(format("%s times info cost %s", n, skynet.now() - t))

        local t = skynet.now()
        local order
        local n = 3000000
        for i = 1, n do
            order = rank:get_order(1100)
        end
        print("order is", order)
        print(format("%s times getorder cost %s", n, skynet.now() - t))
    end
    random_test()
    test()
    stress()
end

skynet.start(function()
    lru()
    rank()
end)
