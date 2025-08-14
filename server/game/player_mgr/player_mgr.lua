local pcall = pcall
local skynet = require "skynet"
local zstd = require "common.tool.zstd"

local db_data = {}
local tickfunc = {}

local save_db = function()
end

skynet.fork(function()
    while true do
        skynet.sleep(100)
        pcall(function()
            save_db()
        end)
    end
end)

return {
    get_db_data = function()
        return db_data
    end,
    add_tick = function(name, func)

    end
}
