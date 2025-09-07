local require = require
local world = require "map.func"

local M = {}

M.init = function()
    world.init({})
    world.flush_resource()
    for i = 1, 10 do
        local troop = {}
        world.add_troop(1, {40, 40, 50, 50}, troop)
    end
end

return M
