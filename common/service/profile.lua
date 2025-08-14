local print, dump, table, pairs = print, dump, table, pairs
local SERVICE_NAME = SERVICE_NAME
local skynet = require "skynet"

local PRINT_PROFILE = 100 * 30

local data = {}

local M = {
    add_cmd_profile = function(cmd, tm)
        if not data[cmd] then
            data[cmd] = {
                n = 0,
                tm = 0
            }
        end
        local cmd_data = data[cmd]
        cmd_data.n = cmd_data.n + 1
        cmd_data.tm = cmd_data.tm + tm
    end
}

local statistic = function()
    local arr = {}
    for k, v in pairs(data) do
        table.insert(arr, {
            cmd = k,
            n = v.n,
            tm = v.tm
        })
    end

    table.sort(arr, function(lhs, rhs)
        return lhs.tm > rhs.tm
    end)

    print(SERVICE_NAME, "profile info", dump(arr))
end

skynet.fork(function()
    while true do
        skynet.sleep(PRINT_PROFILE)
        statistic()
        data = {}
    end
end)

return M
