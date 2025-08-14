local require, error, print, string, split = require, error, print, string, split
local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"

local mode, func_path, static_dir = ...

if mode == "agent" then
    local pairs, io = pairs, io
    local urllib = require "http.url"
    local json = require "common.tool.json"
    local response = function(fd, write, ...)
        local ok, err = httpd.write_response(write, ...)
        if not ok then
            print(string.format("fd = %d, %s", fd, err))
        end
    end
    local gen_interface = function(protocol, fd)
        return {
            init = nil,
            close = nil,
            read = sockethelper.readfunc(fd),
            write = sockethelper.writefunc(fd)
        }
    end
    local cache = {}
    local parse_static_path = function(path)
        if path == "/" then
            path = "/index.html"
        end
        local file_name = static_dir .. path
        if cache[file_name] then
            return cache[file_name]
        end
        local f = io.open(file_name, "r")
        if not f then
            return
        end
        local str = f:read("*a")
        cache[file_name] = str
        -- print("file_name", file_name, #str)
        f:close()
        return str
    end

    local funcs = require(func_path)

    local httpd_process = function(fd)
        local interface = gen_interface("http", fd)
        local code, url, method, header, body = httpd.read_request(interface.read, 8192)
        local ret
        if code then
            if code ~= 200 then
                response(fd, interface.write, code)
                return socket.close(fd)
            end
        end

        local path, query = urllib.parse(url)
        print("path", path, #query, #body)
        if static_dir then
            ret = parse_static_path(path)
            if ret then
                response(fd, interface.write, code, ret)
                return socket.close(fd)
            end
        end

        local params = {}
        if query and #query > 0 then
            for k, v in pairs(query) do
                params[k] = v
            end
        end
        if body and #body > 0 then
            print(body)
            local obj = json.decode(body)
            for k, v in pairs(obj) do
                params[k] = v
            end
        end
        ret = funcs[path](params)
        response(fd, interface.write, code, ret or "404 NOT FOUND")
        socket.close(fd)
    end

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, fd)
            socket.start(fd)
            httpd_process(fd)
        end)
    end)
else
    local mgr = {}

    --[[ obj 
        port = 0,
        agent_num = 0,
        func_path = "server.web.httpd.func"
        white_ip = {}
        static_dir = "server/web/static"
    ]]
    mgr.start_web = function(obj)
        local port = obj.port
        if not port then
            error("start web error no port")
        end
        local func_path = obj.func_path
        if not func_path then
            error("start web error no func_path")
        end
        local agent_num = obj.agent_num or 2
        local white_ip = obj.white_ip
        local static_dir = obj.static_dir

        local agent = {}
        for i = 1, agent_num do
            agent[i] = skynet.newservice("common/tool/web", "agent", func_path, static_dir)
        end
        local balance = 1
        local lfd = socket.listen("0.0.0.0", port)
        socket.start(lfd, function(fd, addr)
            print(string.format("recv from %s balance %d", addr, balance, static_dir))
            local addr_ip = split(addr, ":")[1]
            if white_ip and not white_ip[addr_ip] then
                return socket.close(fd)
            end
            skynet.send(agent[balance], "lua", fd)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
    end

    return mgr
end
