local require, print, dump = require, print, dump
local table, pairs, next = table, pairs, next
local os, tostring = os, tostring
local skynet = require "skynet"
local mgrs = require "server.game.game.mgrs"
local lrank = require "lutil.rank"

local dbdata = mgrs.dbdata
dbdata.ranks = dbdata.ranks or {}
local dbranks = dbdata.ranks

local update_mark = {}
local rankid_core = {}
local M = {}

M.init = function(dbranks)
    for rankid, rank in pairs(dbranks) do
        local core = lrank.create(rank.num)
        local rinfo = rank.info
        for i = 1, #rinfo, 3 do
            core:add(rinfo[i], rinfo[i + 1], rinfo[i + 2])
        end
    end
end

M.tick = function()
    for rankid, core in pairs(update_mark) do
        local rank = dbranks[rankid]
        if rank then
            rank.info = core:info(1, rank.num)
        end
    end
    update_mark = {}
end

M.create_rank = function(rankid, num)
    dbranks[rankid] = dbranks[rankid] or {
        id = rankid,
        num = num,
        arr = nil
    }

    rankid_core[rankid] = lrank.create(num)
end

M.del_rank = function(rankid)
    dbranks[rankid] = nil
    rankid_core[rankid] = nil
end

M.add_score = function(rankid, id, score)
    local core = rankid_core[rankid]

    core:add(id, score, os.time())
    update_mark[rankid] = core
end

M.get_info = function(rankid, lowerb, upperb, meid)
    local core = rankid_core[rankid]

    local ret = {}
    ret.meid = core:get_order(meid)
    ret.info = core:info(lowerb, upperb)
    return ret
end

local test = function()
    M.create_rank(1, 5, 100)
    M.add_score(1, tostring(10), 10)
    M.add_score(1, tostring(20), 5)
    print(dump(dbranks))
    print(dump(M.get_info(1, 1, 5, tostring(20))))
    skynet.timeout(200, function ()
        print(dump(dbranks))
    end)
end

mgrs.add("ranks", M)
return M
