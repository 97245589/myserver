local require, print, dump, string = require, print, dump, string
local world = require "map.func"
local skynet = require "skynet"
local format = string.format

local M = {}

local test_troop = function()
    world.add_entity(5, 5, 1, {
        type = "entity"
    })
    world.add_troop(2, {9, 9, 5, 5}, {
        type = "trooptest"
    })

    for i = 1, 12000 do
        world.add_troop(1, {1, 1, 500, 500}, {})
    end
end

local test_flush = function()
    local t = skynet.now()
    world.flush_resource()
    print("flush 1000*1000 cost", skynet.now() - t)
    print(dump(world.area_entities(10, 10, 3)))

    local t = skynet.now()
    local n = 10000
    for i = 1, n do
        world.area_entities(20, 20, 10)
    end
    print(format("area_entities: %s times cost %s", n, skynet.now() - t))
end

M.init = function()
    world.init({
        increid = 0,
        entities = {},
        troops = {},
        world_len = 1000,
        world_wid = 1000
    })
    test_troop()
end

return M
