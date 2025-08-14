local require = require
require "common.tool.lua_tool"
local skynet = require "skynet"
local web = require "common.tool.web"

skynet.start(function()
    web.start_web({
        port = skynet.getenv("web_port") or 8010,
        func_path = "server.web.httpd.func",
        static_dir = "server/web/static",
        white_ip = {
            ["127.0.0.1"] = 1
        }
    })
end)
