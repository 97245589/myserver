local require, print, dump = require, print, dump
local table, pairs, next = table, pairs, next
local os, tostring = os, tostring
local skynet = require "skynet"
local mgrs = require "server.game.player_mgr.mgrs"
local lrank = require "lutil.rank"

local dbdata = mgrs.dbdata
dbdata.ranks = dbdata.ranks or {}
local dbranks = dbdata.ranks

local tick_info = {}
local tp_ranks = {}
local M = {}

M.init = function(dbranks)
    for rankid, rank in pairs(dbranks) do
        local core = M.add_type_rank(rankid, rank.tp, rank.num)
        local rinfo = rank.info
        for i = 1, #rinfo, 3 do
            core:add(rinfo[i], rinfo[i + 1], rinfo[i + 2])
        end
    end
end

M.tick = function()
    for rankid, core in pairs(tick_info) do
        local rank = dbranks[rankid]
        local info = core:info()
        rank.arr = info.arr
        rank.map = info.map
    end
    tick_info = {}
end

M.add_type_rank = function(rankid, tp, num)
    local core = lrank.create_rank(num)
    tp_ranks[tp] = tp_ranks[tp] or {}
    tp_ranks[tp][rankid] = core
    return core
end

M.create_rank = function(rankid, tp, num)
    dbranks[rankid] = dbranks[rankid] or {
        id = rankid,
        tp = tp,
        num = num,
        arr = nil,
        map = nil
    }

    M.add_type_rank(rankid, tp, num)
end

M.del_rank = function(rankid)
    local rank = dbranks[rankid]
    dbranks[rankid] = nil
    if not rank then
        return
    end
    local tp = rank.tp
    if tp_ranks[tp] then
        tp_ranks[tp][rankid] = nil
        if not next(tp_ranks[tp]) then
            tp_ranks[tp] = nil
        end
    end
end

M.add_score = function(tp, id, score)
    local tpranks = tp_ranks[tp]
    if not tpranks then
        print("rank add err no tp", tp, id, score)
        return
    end

    for rankid, core in pairs(tpranks) do
        core:add(id, score, os.time())
        tick_info[rankid] = core
    end
end

M.get_info = function(rankid, id, num)
    local rank = dbranks[rankid]
    if not rank or not rank.arr then
        return
    end

    local c = 0
    local arr = rank.arr
    local ret = {}
    for i = 1, #arr, 3 do
        table.insert(ret, arr[i])
        table.insert(ret, arr[i + 1])
        c = c + 1
        if c >= num then
            break
        end
    end
    return ret
end

local test = function()
    M.create_rank(1, 5, 100)
    M.add_score(5, tostring(10), 10)
    M.add_score(5, tostring(20), 5)
    print(dump(dbranks))
    skynet.timeout(300, function()
        print(dump(dbranks))
        print(dump(tp_ranks))
    end)
end
test()

mgrs.add("ranks", M)
return M
