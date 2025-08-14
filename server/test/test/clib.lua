require "common.tool.lua_tool"
local require, math, tostring = require, math, tostring
local print, print_v, dump = print, print_v, dump
local skynet = require "skynet"
local format = string.format

local ranktest = function()
    print("ranttest ===========")

    local rank_mgr = require "common.func.rank"
    local random = math.random

    local rank = rank_mgr.new_rank(10)
    for i = 1, 1000 do
        rank.add(tostring(random(20)), random(10), i)
    end
    print("dump info", rank.dump())
    print("get rank info", dump(rank.rankinfo(3)), dump(rank.rankinfo()))

    local t = skynet.now()
    local trank = rank_mgr.new_rank(1000)
    local n = 1e6
    for i = 1, n do
        trank.add(tostring(random(2000)), random(1000), i)
    end
    print(format("rank insert %s times cost %s", n, skynet.now() - t))
    t = skynet.now()
    local ret
    n = 1e4
    for i = 1, n do
        ret = trank.rankinfo(1000)
    end
    print(format("rank getinfo %s times cost %s", n, skynet.now() - t), #ret)
end

local lrutest = function()
    print("lrutest ===========")

    local lru_mgr = require "common.func.lru"

    local data = {}
    local lru = lru_mgr.create_lru(10, function(id)
        data[id] = nil
    end)

    for i = 1, 100 do
        local id = tostring(math.random(20))
        data[id] = 1
        lru.update(id)
    end
    print(lru.dump())
    print_v(data)
end

skynet.start(function()
    lrutest()
    ranktest()
end)
