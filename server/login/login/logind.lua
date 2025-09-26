local mode = ...

if mode == "child" then
    require "common.tool.lua_tool"
    local require, string, pcall = require, string, pcall
    local print, dump = print, dump

    local skynet = require "skynet"
    local socket = require "skynet.socket"
    local crypt = require "skynet.crypt"

    local config_load = require "common.service.config_load"
    local proto = config_load.proto()
    local host = proto.host

    local send_package = function(fd, pack)
        local package = string.pack(">s2", pack)
        socket.write(fd, package)
    end

    local get_req = function(fd)
        local len = socket.read(fd, 2)
        len = len:byte(1) * 256 + len:byte(2)
        local msg = socket.read(fd, len)
        return host:dispatch(msg)
    end

    local exchange = function(fd, spub)
        local _, name, args, res = get_req(fd)

        local cpub = args.cpub
        if name ~= "exchange" or not cpub then
            return
        end
        send_package(fd, res({
            code = 0,
            spub = spub
        }))
        return cpub
    end

    local verify = function(fd, secret)
        local _, name, args, res = get_req(fd)
        local verify = args.verify
        if name ~= "login_verify" or not verify then
            return
        end
        local v, pv = verify[1], verify[2]
        if not v or not pv then
            return
        end
        pv = crypt.desdecode(secret, pv)
        if v ~= pv then
            return
        end
        send_package(fd, res({
            code = 0
        }))
        return true
    end

    local choose_gameserver = function(fd, secret)
        local _, name, args, res = get_req(fd)
        local acc, server = args.acc, args.server
        if name ~= "choose_gameserver" or not acc or not server then
            return
        end

        local ret = skynet.call("info", "lua", "login_req", acc, server, secret)
        if not ret then
            return
        end
        send_package(fd, res(ret))
        return true
    end

    local login = function(fd, addr)
        local spri = crypt.randomkey()
        local spub = crypt.dhexchange(spri)

        local cpub = exchange(fd, spub)
        if not cpub then
            return
        end

        local secret = crypt.dhsecret(cpub, spri)
        if not verify(fd, secret) then
            return
        end

        if not choose_gameserver(fd, secret) then
            return
        end
    end

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, fd, addr)
            socket.start(fd)
            socket.limit(fd, 4096)
            pcall(login, fd, addr)
            socket.close(fd)
            skynet.response()(false)
        end)
    end)

else
    local require, print, table = require, print, table
    local skynet = require "skynet"
    local socket = require "skynet.socket"
    local cmds = require "common.service.cmds"
    local env = require "common.func.env"

    local addrs = {}
    local instance = 2
    for i = 1, instance do
        local addr = skynet.newservice("server/login/login/logind", "child")
        table.insert(addrs, addr)
    end

    local id = socket.listen("0.0.0.0", env.gate_port())
    socket.start(id, function(fd, addr)
        local s = addrs[fd % instance + 1]
        skynet.send(s, "lua", fd, addr)
    end)
end
