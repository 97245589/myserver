local require, print, dump = require, print, tdump
local skynet = require "skynet"
local os, table, pairs, next = os, table, pairs, next
local time = require "common.func.time"
local config = require"common.service.config_load".excel_config
local common = require "server.game.game_common"
local mgrs = require "server.game.player_mgr.mgrs"

local dbdata = mgrs.dbdata
dbdata.activities = dbdata.activities or {}
local activities = dbdata.activities

local act_cfgs = config("act_test")

local M = {
    impls = {}
}

M.exec_act_cb = function(id, cbname, ...)
    local impl = M.impls[id]
    if not impl then
        -- print("no act impl", id)
        return
    end
    local func = impl[cbname]
    if not func then
        -- print("no actmgr cb", id, cbname)
        return
    end
    return func(...)
end

M.get_activities = function()
    return activities
end

M.new_act = function(actid, starttm, endtm)
    return {
        actid = actid,
        starttm = starttm,
        endtm = endtm,
        isopen = false
    }
end

local tick_mark = false
M.load_activities = function()
    for actid, actcfg in pairs(act_cfgs) do
        local act = activities[actid]
        if act then
            goto cont
        end
        local cstarttm, cendtm = time.start_end(actcfg)
        if not cstarttm then
            goto cont
        end
        activities[actid] = M.new_act(actid, cstarttm, cendtm)
        ::cont::
    end
    common.send_all_player_service("activities_info", activities)
    tick_mark = true
end
skynet.timeout(100, M.load_activities)

M.tick = function()
    if not tick_mark then
        return
    end
    local opens = {}
    local closes = {}
    local tm = os.time()
    for actid, act in pairs(activities) do
        -- print("actid", actid, time.format(act.starttm), time.format(act.endtm))
        if act.endtm and tm >= act.endtm then
            activities[actid] = nil
            M.exec_act_cb(actid, "close", actid)
            table.insert(closes, actid)

            local actcfg = act_cfgs[actid]
            if not actcfg then
                goto cont
            end
            local cstarttm, cendtm = time.start_end_by_lastend(actcfg, act.endtm)
            if not cstarttm then
                goto cont
            end
            activities[actid] = M.new_act(actid, cstarttm, cendtm)
            goto cont
        end

        if tm >= act.starttm then
            if not act.isopen then
                act.isopen = true
                M.exec_act_cb(actid, "open", actid)
                table.insert(opens, actid)
                goto cont
            end
        end
        ::cont::
    end
    if next(opens) or next(closes) then
        opens = next(opens) and opens or nil
        closes = next(closes) and closes or nil
        common.send_all_player_service("activities_info", activities, opens, closes)
    end
end

mgrs.add("acts_mgr", M)
return M
