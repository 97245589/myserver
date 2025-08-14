local skynet = require "skynet"

skynet.start(function()
    skynet.newservice("debug_console", skynet.getenv("debug_console_port"))
    local server_name = skynet.getenv("server_name")
    local init_service = "server/" .. server_name .. "/init"
    skynet.newservice(init_service)
    skynet.exit()
end)
