local require, print, dump = require, print, dump
local table, pairs, next = table, pairs, next
local skynet = require "skynet"
local rank = require "common.func.rank"
local mgrs = require "server.game.player_mgr.mgrs"
local rank_tool = require "common.func.rank"

local dbdata = mgrs.dbdata
dbdata.ranks = dbdata.ranks or {}
local dbranks = dbdata.ranks

local tick_info = {}
local tp_ranks = {}
local M = {}

M.init = function(dbranks)

end

M.tick = function()
    for rankid, core in pairs(tick_info) do
        local rank = dbranks[rankid]
        rank.info = core.rankinfo()
    end
    tick_info = {}
end

M.create = function(rankid, tp)
    dbranks[rankid] = dbranks[rankid] or {
        id = rankid,
        tp = tp,
        info = nil
    }

    local core = rank_tool.new_rank(1000)
    tp_ranks[tp] = tp_ranks[tp] or {}
    tp_ranks[tp][rankid] = {
        id = rankid,
        core = core
    }
end

M.del = function(rankid)
    local rank = dbranks[rankid]
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

M.add = function(tp, id, score)
    local tpranks = tp_ranks[tp]
    if not tpranks then
        print("rank add err no tp", tp, id, score)
        return
    end

    for rankid, tprank in pairs(tpranks) do
        local core = tprank.core
        core.add(id, score)
        tick_info[rankid] = core
    end
end

M.get_info = function(rankid, num, id)
    local rank = dbranks[rankid]
    if not rank or not rank.info then
        return
    end

    local c = 0
    local rinfo = rank.info
    local ret = {}
    for i = 1, #rinfo, 3 do
        table.insert(ret, rinfo[i])
        table.insert(ret, rinfo[i + 1])
        c = c + 1
        if c >= num then
            break
        end
    end
    return ret
end

mgrs.add("ranks", M)
return M
