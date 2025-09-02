local require, print, dump = require, print, dump
local mgrs = require "server.game.player_mgr.mgrs"

local dbdata = mgrs.dbdata
dbdata.activities = dbdata.activities or {}
local activities = dbdata.activities

local act_cfgs = {
    [1] = {}
}

local M = {}

M.tick = function()
    print("act tick ===")
end

M.get_activities = function()
    return activities
end

mgrs.add("activities", M)
return M
