local require, os, setmetatable = require, os, setmetatable
local skynet = require "skynet"
local lrank = require "lutil.lrank"

local M = {}
M.new_rank = function(num)
    local core = lrank.create_lrank(num)
    return {
        add = function(id, score, time)
            core:add(id, score, time or skynet.time())
        end,
        dump = function()
            return core:dump()
        end,
        rankinfo = function(num)
            return core:arr_info(num)
        end
    }
end

return M
