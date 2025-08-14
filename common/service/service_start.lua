local skynet = require "skynet"

local start_func = function(name)
    require "common.tool.lua_tool"
    local require, print, string, pcall = require, print, string, pcall
    local profile = require "skynet.profile"
    require "skynet.manager"
    local codecache = require "skynet.codecache"
    codecache.mode "EXIST"
    local cmds = require "common.service.cmds"
    local profile_info = require "common.service.profile"
    local config_load = require "common.service.config_load"
    local SERVICE_NAME = SERVICE_NAME

    if name then
        skynet.register(name)
    end

    local package_reload = require "common.service.service_reload"
    local service_dir = package_reload.get_service_dir()
    local hotreload = function()
        -- codecache.clear()
        config_load.reload()
        package_reload.remove_hotreload_package()
        package_reload.dir_require(service_dir .. "/cmd")
        package_reload.dir_require(service_dir .. "/mgr")
        print(SERVICE_NAME, "reload success")
    end

    cmds.hotreload = hotreload

    skynet.dispatch("lua", function(_, _, cmd, ...)
        profile.start()
        local func = cmds[cmd]
        if func then
            local ok, ret = pcall(func, ...)
            if ok then
                skynet.retpack(ret)
            else
                skynet.response()(false)
            end
        else
            skynet.response()(false)
            print(SERVICE_NAME .. " service lua command not found", cmd)
        end
        local time = profile.stop()
        local cmd_name = "rpc.." .. cmd
        profile_info.add_cmd_profile(cmd_name, time)
    end)

    package_reload.dir_require(service_dir)
    package_reload.add_no_hotreaload_package()
    hotreload()
end

return {
    start = function(name, load_fork)
        skynet.start(function()
            if load_fork then
                skynet.fork(start_func, name)
            else
                start_func(name)
            end
        end)
    end
}
