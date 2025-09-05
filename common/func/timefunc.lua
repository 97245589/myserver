local require, os = require, os
local time = require "common.func.time"
local table, pairs, ipairs, next = table, pairs, ipairs, next

local M = {}

local ctr_load = function(cfgs, objs)
    for cid, cfg in pairs(cfgs) do
        local obj = objs[cid]
        if obj then
            goto cont
        end
        local cstarttm, cendtm = time.start_end(cfg)
        if not cstarttm then
            goto cont
        end
        objs[cid] = {
            id = cid,
            starttm = cstarttm,
            endtm = cendtm,
            isopen = false
        }
        ::cont::
    end
end

local ctr_tick = function(cfgs, objs)
    local tm = os.time()
    local opens = {}
    local closes = {}

    for id, obj in pairs(objs) do
        if obj.endtm and tm >= obj.endtm then
            table.insert(closes, id)

            local cfg = cfgs[id]
            if not cfg then
                objs[id] = nil
                goto cont
            end
            local cstarttm, cendtm = time.start_end_by_lastend(cfg, obj.endtm)
            if not cstarttm then
                objs[id] = nil
                goto cont
            end
            objs[id] = {
                id = id,
                starttm = cstarttm,
                endtm = cendtm,
                isopen = false
            }
            goto cont
        end

        if tm >= obj.starttm then
            if not obj.isopen then
                obj.isopen = true
                table.insert(opens, id)
                goto cont
            end
        end

        ::cont::
    end
    return next(opens) and opens or nil, next(closes) and closes or nil
end

M.control = function()
    return {
        load = ctr_load,
        tick = ctr_tick
    }
end

local handle_open = function(player, pobjs, id, starttm, cb)
    local open = function(pobj)
        pobj.id = id
        pobj.isopen = true
        pobj.starttm = starttm
        cb(id, "open", player, pobj)
    end

    pobjs[id] = pobjs[id] or {}
    local pobj = pobjs[id]

    if not pobj.isopen then
        open(pobj)
        return
    end

    if pobj.starttm ~= starttm then
        cb(id, "close", player, pobj)
        open(pobj)
        return
    end
end

local handle_close = function(player, pobjs, id, cb)
    local pobj = pobjs[id]
    pobjs[id] = nil
    if not pobj or not pobj.isopen then
        return
    end
    cb(id, "close", player, pobj)
end

local isopen = function(obj, nowtm)
    if not obj then
        return
    end
    if nowtm < obj.starttm then
        return
    end
    if not obj.endtm or nowtm < obj.endtm then
        return true
    end
end

local check = function(player, pobjs, objs, cb)
    local nowtm = os.time()
    for id, obj in pairs(objs) do
        if isopen(obj, nowtm) then
            handle_open(player, pobjs, id, obj.starttm, cb)
        else
            handle_close(player, pobjs, id, cb)
        end
    end

    for id, pobj in pairs(pobjs) do
        if not objs[id] then
            handle_close(player, pobjs, id, cb)
        end
    end
end

local handle_closes = function(players, attrname, closes, objs, cb)
    if not closes then
        return
    end
    for _, id in ipairs(closes) do
        for playerid, player in pairs(players) do
            handle_close(player, player[attrname], id, cb)
        end
    end
end

local handle_opens = function(players, attrname, opens, objs, cb)
    if not opens then
        return
    end
    for _, id in ipairs(opens) do
        local starttm = objs[id].starttm
        for playerid, player in pairs(players) do
            handle_open(player, player[attrname], id, starttm, cb)
        end
    end
end

M.player = function()
    return {
        check = check,
        handle_opens = handle_opens,
        handle_closes = handle_closes
    }
end

return M
