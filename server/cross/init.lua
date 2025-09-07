local skynet = require "skynet"

skynet.start(function()
    skynet.newservice("server/cross/cluster/start", "cluster")
    skynet.newservice("server/cross/mapmgr/start", "mapmgr", 1)
    skynet.exit()
end)
