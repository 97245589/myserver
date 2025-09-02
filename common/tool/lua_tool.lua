local skynet = require "skynet"
local SERVICE_NAME = SERVICE_NAME
local date = os.date
print = skynet.error
local time = os.time
local stime = skynet.time
local mfloor = math.floor
os.time = function(p)
    if p then
        return time(p)
    else
        return mfloor(stime())
    end
end

local print, type, setmetatable, getmetatable = print, type, setmetatable, getmetatable
local table, pairs, ipairs, tconcat, tinsert, next = table, pairs, ipairs, table.concat, table.insert, next
local string, tostring, srep = string, tostring, string.rep

local tdump = function(root)
    local cache = {
        [root] = "."
    }
    local function _dump(t, space, name)
        local temp = {}
        for k, v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
            else
                tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
            end
        end
        return tconcat(temp, "\n" .. space)
    end
    local str = "\n" .. _dump(root, "", "")
    return str
end
print_r = function(v)
    print(tdump(v))
end

local odump = function(v, max_depth)
    local tmp = {}
    local cache = {}
    local _dump

    local pack_k = function(k)
        local r
        if type(k) == "number" then
            r = "[" .. k .. "]"
        elseif type(k) == "string" then
            r = k
        end
        return r
    end

    _dump = function(v, space, k, depth)
        k = k or ""
        local nspace = space .. "    "
        local k = space .. pack_k(k) .. " = "

        depth = depth + 1
        if type(v) == "number" then
            tinsert(tmp, k .. v .. ",")
        elseif type(v) == "string" then
            tinsert(tmp, k .. '"' .. v .. '",')
        elseif type(v) == "table" then
            if cache[v] then
                tinsert(tmp, k .. cache[v])
                return
            end
            cache[v] = k
            if max_depth and depth >= max_depth then
                tinsert(tmp, k .. "maxdepth" .. ",")
            else
                tinsert(tmp, k .. "{")
                for vk, vv in pairs(v) do
                    _dump(vv, nspace, vk, depth)
                end
                tinsert(tmp, space .. "},")
            end
        else
            tinsert(tmp, k .. type(v) .. ",")
        end
    end

    _dump(v, "", "", -1)
    return tconcat(tmp, "\n")
end
dump = odump
local dump = dump
print_v = function(v)
    print(dump(v))
end

local tclone
tclone = function(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return new_table
        -- return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end
clone = tclone

split = function(str, sp)
    sp = sp or " "
    if type(sp) == "number" then
        sp = string.char(sp)
    end

    local patt = string.format("[^%s]+", sp)
    -- print(patt)
    local arr = {}
    for k in string.gmatch(str, patt) do
        table.insert(arr, k)
    end
    return arr
end

arr_remove = function(arr, func)
    for i = #arr, 1, -1 do
        if func(arr[i]) then
            table.remove(arr, i)
        end
    end
end
