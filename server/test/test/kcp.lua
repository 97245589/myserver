local print, string, os = print, string, os

local skynet = require "skynet"
local socket = require "skynet.socket"
local lkcp = require "lkcp"

local function server()
    local kcps = {}
    local host
    local i = 0
    host = socket.udp(function(str, from)
        if not kcps[from] then
            local kcp = lkcp.create_lkcp(1, host, from)
            kcps[from] = {
                kcp = kcp,
                heartbeat = skynet.now()
            }
        end
        local kcp = kcps[from].kcp
        local data = kcp:recv(str)
        print("recv from", socket.udp_address(from), data)
        kcp:update(i)
        i = i + 1
    end, "0.0.0.0", 8765)

end

local function client(name)
    local host, kcp_cli
    host = socket.udp(function(str, from)
        -- print("client recv", str, from)
        kcp_cli:recv(str)
    end)
    socket.udp_connect(host, "0.0.0.0", 8765)
    kcp_cli = lkcp.lkcp_client(1, host)
    for i = 1, 1000 do
        skynet.sleep(1)
        kcp_cli:send(name .. "   " .. i)
        kcp_cli:update(i)
    end
end

local child = ...
if not child then
    skynet.start(function()
        skynet.fork(server)
        for i = 1, 3 do
            skynet.newservice("server/test/test/kcp", "child" .. i)
        end
    end)
else
    skynet.start(function()
        skynet.fork(client, child)
    end)
end
