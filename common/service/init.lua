require "common.tool.tool"
local skynet = require "skynet"
local cmds = require "common.service.cmds"

local load_files = function(depth)
    local require = require
    local string = string
    local SERVICE_NAME = SERVICE_NAME

    local service_dir = SERVICE_NAME:gsub("/[^/]+$", "")
    local str = string.format('find %s -maxdepth %s -mindepth %s -name "*.lua"', service_dir, depth, depth)

    local f = io.popen(str)
    for line in f:lines() do
        local file_name = string.sub(line, 1, -5)
        if file_name == SERVICE_NAME then
            goto cont
        end
        local name = string.match(file_name, "([^/]+)$")
        if name == "reload" then
            goto cont
        end

        local m = string.gsub(file_name, '/', '.')
        require(m)
        -- print("require", SERVICE_NAME, m)
        ::cont::
    end
    f:close()
end

local init = function(tmout)
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local func = cmds[cmd]
            if func then
                func(...)
            else
                skynet.response()(false)
            end
        end)

        skynet.timeout(tmout or 0, function()
            load_files(1)
            load_files(2)
        end)
    end)
end

return init
