local require, print = require, print
local client_req = require "server.game.player.client_req"
local req = client_req.client_req

req.push_test = function(player, args)
    return {
        code = 0
    }
end
