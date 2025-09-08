local require, print, dump, string = require, print, dump, string
local pairs = pairs
local world = require "map.func"
local skynet = require "skynet"
local format = string.format

local handle = {
    entityadd = function(watchids, entity)
        print("entityadd", dump(watchids), dump(entity))
    end,
    entitydel = function(watchids, entity)
        print("entitydel", dump(watchids), dump(entity))
    end,
    troopupdate = function(watchid, obj)
        -- print("troopupdate", watchid, dump(obj))
        skynet.packstring(watchid, obj)
    end
}
world.notify_watches = function(cmd, ...)
    handle[cmd](...)
end

world.troop_arrive = function(troop)
    local path = troop.path
    local dx, dy = path[#path - 1], path[#path]
    local entity = world.get_entity_bypos(dx, dy)
    -- print("troop arrived", dump(troop), dump(entity))
end

local test_troop_watch = function()
    --[[
    for i = 1, 3 do
        world.add_watch(i, 1, 500, 500)
    end

    for i = 1, 10 do
        local troop = {
            type = "test"
        }
        world.add_troop(5, {480, 480, 500, 500}, troop)
    end
    ]]

    for i = 1, 4000 do
        world.add_watch(i, 1, 500, 500)
    end
    for i = 1, 12000 do
        local troop = {
            type = "test"
        }
        world.add_troop(5, {480, 480, 500, 500}, troop)
    end
end

local test_watch = function()
    for i = 1, 10 do
        world.add_watch(i, 1, 50, 50)
    end
    local entity = {
        type = "watchtest"
    }
    world.add_entity(45, 45, 1, entity)
    world.del_entity(entity.worldid)

    --[[
    for i = 1, 4000 do
        world.add_watch(i, 1, 50, 50)
    end

    local t = skynet.now()
    for i = 1, 10000 do
        local entity = {
            type = "test"
        }
        world.add_entity(50, 50, 1, entity)
        world.del_entity(entity.worldid)
    end
    print("entity watch test", skynet.now() - t)
    print(dump(world.area_entities(50, 50, 10)))
    ]]
end

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

local M = {}

M.init = function()
    world.init({
        increid = 0,
        entities = {},
        troops = {},
        world_len = 1000,
        world_wid = 1000
    })
    test_troop_watch()
end

return M
