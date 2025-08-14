local require, print, io, dofile = require, print, io, dofile
local sproto = require "sproto"

local proto_data = nil
local excel_configs = {}
local M = {}

M.reload = function()
    excel_configs = {}
end

M.proto = function()
    if proto_data then
        return proto_data
    end
    -- print("config_load proto")
    local file = io.open("common/config/game.sproto", "r")
    local str = file:read("*a")
    file:close()
    local sp = sproto.parse(str)
    local host = sp:host("package")
    proto_data = {
        sp = sp,
        host = host,
        push_req = host:attach(sp)
    }
    return proto_data
end

M.excel_config = function(name)
    if excel_configs[name] then
        return excel_configs[name]
    end

    -- print("config_load excel config", name)
    excel_configs[name] = dofile("common/config/" .. name .. ".lua")
    return excel_configs[name]
end

return M
