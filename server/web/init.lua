local skynet = require "skynet"

skynet.start(function ()
    skynet.newservice("server/web/httpd/start")
    skynet.exit()
end)