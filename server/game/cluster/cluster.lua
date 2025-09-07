local require, print = require, print
require "common.service.cluster_start"
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local cluster = require "skynet.cluster"
local cmds = require "common.service.cmds"
local gamecommon = require "server.game.game_common"

local serverid = skynet.getenv("server_id")
local ip = skynet.getenv("ip")
local gameserver_info = {
    serverid = serverid,
    host = ip .. ":" .. skynet.getenv("gate_port")
}

cmds.gameserver_info = function()
    return gameserver_info
end
