local require, pcall = require, pcall
local print = print
local skynet = require "skynet"
local mgrs = require "server.game.player_mgr.mgrs"
local dbdata = require "server.game.player_mgr.dbdata"

skynet.timeout(100, function ()
    mgrs.start_timeout()
    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local ok, ret = pcall(function()
                mgrs.tick()
                dbdata.save()
            end)
    
            if not ok then
                print("tick arr", ret)
            end
        end
    end)
end)


