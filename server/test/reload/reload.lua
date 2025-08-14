local require = require
local print, dump = print, dump
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local config_load = require "common.service.config_load"

skynet.fork(function()
    while true do
        skynet.sleep(300)
        print("start hotreload ========", skynet.now())
        cmds.hotreload()
        local item = config_load.excel_config("item_test")
        print("item data:", dump(item))
    end
end)
