local skynet = require "skynet"

skynet.start(function()
    skynet.newservice("server/test/reload/start")
    skynet.exit()
end)
