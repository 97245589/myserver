local require = require
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local client_req = require "server.game.player.client_req"
local req = client_req.client_req

local map_send = function(player)
    
end

local map_call = function(player)

end

req.enter_world = function(player, args)
    map_call("enter_world", player, args)
end
