local require, pcall = require, pcall
local print = print
local skynet = require "skynet"
local mgrs = require "server.game.game.mgrs"
local dbdata = require "server.game.game.dbdata"

skynet.timeout(100, function()
    mgrs.start_timeout()
    skynet.fork(function()
        while true do
            local ok, ret = pcall(function()
                mgrs.tick()
                dbdata.save()
            end)
            if not ok then
                print("tick arr", ret)
            end
            skynet.sleep(100)
        end
    end)
end)

