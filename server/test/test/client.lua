require "common.tool.lua_tool"
local require, print, dump, tostring = require, print, dump, tostring
local pcall, load = pcall, load
local skynet = require "skynet"
local socket = require "skynet.socket"

local acc, playerid = ...
acc = acc or "2000"
playerid = playerid or "1_2000"

local test = function()
    local client = require "server.test.common.client"
    local send_request = client.send_request
    local recv_data = client.recv_data

    client.client_start({
        acc = acc,
        playerid = playerid,
        local_server = true
    })

    send_request("select_player", {
        acc = acc,
        playerid = playerid
    })
    local _, _, res = recv_data()
    print("select_player", playerid, dump(res))

    skynet.fork(function()
        while true do
            skynet.sleep(1000)
            send_request("push_test", {})
        end
    end)

    skynet.fork(function()
        while true do
            local p1, p2, p3 = recv_data()
            print("recv:", p1, p2, dump(p3))
        end
    end)

    send_request("enter_world")

    skynet.fork(function()
        local stdin = socket.stdin()
        while true do
            local cmdline = socket.readline(stdin, "\n")
            local ok, cmd, p = pcall(load("return " .. cmdline))
            if ok then
                send_request(cmd, p)
            end
        end
    end)

end

skynet.start(function()
    skynet.fork(test)
end)
