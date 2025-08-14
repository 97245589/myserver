local cmds = require "common.service.cmds"
local mgrs = require "server.game.player.mgrs"
local client_req = require "server.game.player.client_req"

local bhotreload = cmds.hotreload

cmds.hotreload = function()
    client_req.load_proto()
    mgrs.clear()
    bhotreload()
end
