local print, dump, require, string = print, tdump, require, string
local acts_tm = require "server.game.game.mgr.acts_tm"
local mgrs = require "server.game.game.mgrs"
local format = string.format

local dbdata = mgrs.dbdata
dbdata.acts_data = dbdata.acts_data or {}
local acts_data = dbdata.acts_data

local impls = acts_tm.impls
impls[10] = {
    open = function(actid)
        -- print(format("act %s open", actid))
    end,
    close = function(actid)
        -- print(format("act %s close", actid))
    end
}

