local require = require
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local client_req = require "server.game.player.client_req"
local pacts_mgr = require "server.game.player.mgr.pacts_mgr"

cmds.player_enter = client_req.player_enter

cmds.activities_info = pacts_mgr.activities_info
