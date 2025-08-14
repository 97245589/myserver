local require, setmetatable = require, setmetatable
local print, string, io, next = print, string, io, next
local table, ipairs = table, ipairs
local json = require "common.tool.json"
local config = require "server.web.httpd.config"

local ret = {}

setmetatable(ret, {
    __index = function(tb, k)
        local f = function()
            print("func path not found", k)
        end
        tb[k] = f
        return f
    end
})

ret["/test"] = function(obj)
    return "hello world"
end

ret["/server_mgr"] = function(obj)
    local cmd, name = next(obj)
    if not cmd then
        return json.encode(config.server_mgr)
    end

    local handle = {
        game_restart = function()
        end,
        game_reload = function()
        end
    }
    handle[name]()
    return name .. " success"
end

ret["/gmplat"] = function(obj)
    local datas = config.gmplat.datas
    local cmd, idx = next(obj)
    if not cmd then
        local arr = {}
        for _, v in ipairs(datas) do
            table.insert(arr, {
                des = v.des
            })
        end
        return json.encode({
            datas = arr
        })
    end

    local gm = datas[idx].gm
    local data = {
        gm = gm
    }
    return json.encode(data)
end

ret["/gmcontent"] = function(obj)
    return json.encode(obj)
end

return ret
