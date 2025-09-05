local require, os, print, dump = require, os, print, dump
local zstd = require "common.tool.zstd"
local mgrs = require "server.game.player_mgr.mgrs"
local time = require "common.func.time"

local M = {
    data = nil
}

M.get_dbdata = function()
    local dbdata = {}
    dbdata.startday = dbdata.startday or os.time()
    time.set_server_start_ts(dbdata.startday)

    M.data = dbdata
    mgrs.dbdata = M.data
end
M.get_dbdata()

M.save = function()
    -- print("dbdata save", dump(M.data))
end

return M
