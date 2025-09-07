local require, print, dump = require, print, dump
local math = math
local world = require "map.world"
local enums = require "common.func.enums"

world.new_resource = function(cx, cy, level)
    world.add_entity(cx, cy, 1, {
        type = enums.entity_resource,
        level = level
    })
end

world.flush_resource = function()
    local world_info = world.get_world_info()
    local world_len = world_info.world_len
    local world_wid = world_info.world_wid
    local FLUSH_SIZE = 10
    for i = 0, (world_len - 1) // FLUSH_SIZE do
        for j = 0, (world_wid - 1) // FLUSH_SIZE do
            local blx = i * FLUSH_SIZE
            local bly = j * FLUSH_SIZE
            local trx = blx + FLUSH_SIZE - 1
            local try = bly + FLUSH_SIZE - 1
            -- print("======", i, j)
            for i = 1, 10 do
                local cx = math.random(blx, trx)
                local cy = math.random(bly, try)
                -- print(cx, cy)
                world.new_resource(cx, cy, math.random(1, 5))
            end
        end
    end
end

return world
