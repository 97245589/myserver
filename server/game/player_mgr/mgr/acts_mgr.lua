local require, print, dump = require, print, tdump
local pairs, ipairs, next = pairs, ipairs, next
local skynet = require "skynet"
local config = require"common.service.config_load".excel_config
local common = require "server.game.game_common"
local mgrs = require "server.game.player_mgr.mgrs"
local timefunc = require "common.func.timefunc"

local dbdata = mgrs.dbdata
dbdata.activities = dbdata.activities or {}
local activities = dbdata.activities

local act_cfgs = config("act_test")

local M = {
    impls = {}
}

local exec_cb = function(id, tp)
    local impl = M.impls[id]
    if not impl then
        return
    end
    local func = impl[tp]
    func(id)
end

local handle_opens_closes = function(opens, closes)
    if opens then
        for _, id in ipairs(opens) do
            exec_cb(id, "open")
        end
    end
    if closes then
        for _, id in ipairs(closes) do
            exec_cb(id, "close")
        end
    end
end

local tick_mark = false
local ctr = timefunc.control()

skynet.timeout(100, function()
    ctr.load(act_cfgs, activities)
    common.send_all_player_service("activities_info", activities)
    tick_mark = true
end)

M.tick = function()
    if not tick_mark then
        return
    end
    local opens, closes = ctr.tick(act_cfgs, activities)
    handle_opens_closes(opens, closes)

    if opens or closes then
        common.send_all_player_service("activities_info", activities, opens, closes)
    end
end

mgrs.add("acts_mgr", M)
return M
