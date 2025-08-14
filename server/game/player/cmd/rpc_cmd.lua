local require = require
local skynet = require "skynet"
local client_req = require "server.game.player.client_req"
local cmds = require "common.service.cmds"

cmds.player_enter = client_req.player_enter
