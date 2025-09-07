local require, print, dump = require, print, tdump
local world = require "map.world"
local skynet = require "skynet"

skynet.fork(function()
    while true do
        skynet.sleep(100)
        -- local t = skynet.now()
        world.tick()
        -- local diff = skynet.now() - t
        -- print("map tick", diff)
    end
end)

world.troop_arrive = function(troop)
    local path = troop.path
    local dx, dy = path[#path - 1], path[#path]
    local entity = world.get_entity_bypos(dx, dy)
end

return world
