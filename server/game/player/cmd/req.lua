local require, print = require, print
local skynet = require "skynet"
local client_req = require "server.game.player.client_req"
local req = client_req.cli_req

req.push_test = function(player, args)
    return {
        code = 0
    }
end
