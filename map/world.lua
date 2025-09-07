local require, print, dump = require, print, tdump
local table, pairs, ipairs, next = table, pairs, ipairs, next
local skynet = require "skynet"
local lworld = require "lworld.world"

local core = lworld.create_lworld()

local world_len, world_wid
local increid

local entities
local troops

local watches = {}
local watch_troops = {}

local M = {}

M.tm = function()
    return skynet.time() * 1000
end

M.gen_worldid = function()
    increid = (increid + 1) & 0xfffffff
    if (increid <= 0) then
        increid = 1
    end
    return increid
end

M.get_world_info = function()
    return {
        increid = increid,
        world_len = world_len,
        world_wid = world_wid,
        entities = entities,
        troops = troops
    }
end

M.init = function(args)
    increid = args.increid or 0
    entities = args.entities or {}
    troops = args.troops or {}
    world_len = args.world_len or 1000
    world_wid = args.world_wid or 1000

    for worldid, entity in pairs(entities) do
        M.add_entity(entity.cx, entity.cy, entity.len, entity)
    end
    for worldid, troop in pairs(troops) do
        M.recover_troop(troop)
    end
    core:init(world_len, world_wid)
end

M.area_entities = function(cx, cy, len)
    local arr = M.area_entities_arr(cx, cy, len)
    if not arr then
        return
    end
    local ret = {}
    for _, worldid in ipairs(arr) do
        ret[worldid] = entities[worldid]
    end
    return ret
end

M.area_entities_arr = function(cx, cy, len)
    return core:area_entities(cx, cy, len)
end

M.get_entity_bypos = function(cx, cy)
    local arr = M.area_entities_arr(cx, cy, 1)
    if not arr then
        return
    end
    local i, worldid = next(arr)
    return entities[worldid]
end

M.add_entity = function(cx, cy, len, entity)
    if (M.area_entities_arr(cx, cy, len)) then
        return
    end
    entity.worldid = entity.worldid or M.gen_worldid()
    entity.cx = cx
    entity.cy = cy
    entity.len = len
    entities[entity.worldid] = entity
    local ws = core:add_entity(cx, cy, len, entity.worldid)
    if ws then
        M.notify_watches("entityadd", ws, entity)
    end
    return true
end

M.del_entity = function(worldid)
    local entity = entities[worldid]
    entities[world_len] = nil
    if not entity then
        return
    end
    local cx = entity.cx
    local cy = entity.cy
    local len = entity.len
    local ws = core:del_entity(cx, cy, len)
    if ws then
        M.notify_watches("entitydel", ws, entity)
    end
end

M.recover_troop = function(troop)
    troops[troop.worldid] = troop
    core:recover_troop(troop)
end

M.add_troop = function(speed, path, troop)
    if speed <= 0 then
        return
    end
    troop.worldid = troop.worldid or M.gen_worldid()

    local tm = M.tm()
    local ret = core:add_troop(troop.worldid, tm, speed, path)
    if not ret then
        return
    end
    troop.speed = speed
    troop.path = path
    troop.tm = tm
    troop.nowpos = 0
    troop.nowx = path[1]
    troop.nowy = path[2]

    troops[troop.worldid] = troop
end

M.del_troop = function(worldid)
    troops[worldid] = nil
    core:del_troop(worldid)
end

M.add_watch = function(src, weigh, cx, cy)
    if not watches[src] then
        watches[src] = M.gen_worldid()
    end
    local worldid = watches[src]
    watch_troops[worldid] = {}
    core:add_watch(worldid, weigh, cx, cy)
    return worldid
end

M.del_watch = function(src)
    local worldid = watches[src]
    if worldid then
        watches[src] = nil
        watch_troops[worldid] = nil
        core:del_watch(worldid)
    end
    return worldid
end

M.troops_move = function(tm)
    local arrive_arr = core:troops_move(tm)
    if not arrive_arr then
        return
    end
    for _, worldid in ipairs(arrive_arr) do
        local troop = troops[worldid]
        troops[worldid] = nil
        if troop then
            M.troop_arrive(troop)
        end
    end
end

M.troops_info = function(tm)
    local arr = core:troops_info()
    for i = 1, #arr, 4 do
        local worldid = arr[i]
        local nowx = arr[i + 1]
        local nowy = arr[i + 2]
        local nowpos = arr[i + 3]

        local troop = troops[worldid]
        if troop then
            troop.nowx = nowx
            troop.nowy = nowy
            troop.nowpos = nowpos
            troop.tm = tm
        end
    end
    -- print("=== troops_info", tm, dump(troops))
end

M.update_watch_troops = function()
    local compare = function(watchid, before, now)
        local notify = {}
        for twid in pairs(now) do
            if before[twid] then
                before[twid] = nil
            else
                notify.add = notify.add or {}
                notify.add[twid] = troops[twid]
            end
        end
        for twid in pairs(before) do
            notify.del = notify.del or {}
            notify.del[twid] = 1
        end
        if next(notify) then
            M.notify_watches("troopupdate", watchid, notify)
        end
    end

    local infos = core:watch_troops()
    if not infos then
        return
    end
    for worldid, info in pairs(infos) do
        local before = watch_troops[worldid]
        watch_troops[worldid] = info
        compare(worldid, before, info)
    end
end

M.tick = function(tm)
    if not world_len then
        return
    end
    tm = tm or M.tm()
    M.troops_move(tm)
    M.troops_info(tm)
    M.update_watch_troops()
end

return M
