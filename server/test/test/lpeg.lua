local require = require
require "common.tool.lua_tool"
local print, print_v, dump = print, print_v, dump
local type, table, ipairs, pairs, load = type, table, ipairs, pairs, load

local skynet = require "skynet"
local lpeg = require "lpeg"

local simple = function()
    local r
    lpeg.locale(lpeg)
    local space = lpeg.space ^ 0

    local name = lpeg.alpha ^ 1
    print(name:match("hahayes"))

    local name = lpeg.C(lpeg.alpha ^ 1) * space
    r = name:match("hahaha")

    local sep = lpeg.S(",;") * space
    local pair = lpeg.Cg(space * name * "=" * space * name) * sep ^ -1
    print(pair:match("hello = world"))

    local mul_pair = lpeg.Ct(pair ^ 0)
    print_v(mul_pair:match("hello = world, test = test1"))

    local mul_pair = lpeg.Cf(lpeg.Ct("") * pair ^ 0, function(tb, v1, v2)
        tb[v1] = v2
        print("---tt", v1, v2, dump(tb))
        return tb
    end)
    mul_pair:match("hello = world, test = testt")
end

local parse_enum = function(str)
    lpeg.locale(lpeg)
    local space = lpeg.space ^ 0

    local var_name_first = (lpeg.alpha + "_") ^ 1
    local var_name_next = (lpeg.alpha + lpeg.alnum + "_") ^ 0
    local var_name = space * lpeg.C(var_name_first * var_name_next) * space

    local enum_start = space * "enum" * space

    local sep = lpeg.S(",\n")
    local elem = lpeg.C((1 - sep) ^ 0)
    local enum_equ = space * "=" * space * elem * space
    local one_enum = lpeg.Ct(var_name * enum_equ ^ 0 * space)
    local enums = one_enum * (sep * one_enum) ^ 0

    local enum_exp = enum_start * var_name * "{" * enums * (lpeg.space + lpeg.S(",};")) ^ 1

    local enum_list = enum_exp ^ 0
    local infos = table.pack(enum_list:match(str))
    return infos
end

local infos_2_enum = function(infos)
    local enums = {}
    local e_str, now_v, checks
    for _, v in ipairs(infos) do
        if type(v) == "string" then
            e_str = v
            now_v = 0
            enums[e_str] = {}
        elseif type(v) == "table" then
            local name, str = table.unpack(v)
            if str then
                now_v = load("return " .. str)()
            end
            enums[e_str][name] = now_v
            now_v = now_v + 1
        end
    end
    return enums
end

local enum_parse = function()
    local enum_str = [[
        enum ATTR {
            HP,
            ATK = 10,
            DEF = 1 << 2,
        };

        enum ACTSTAUTS {
            ON=1,CLOSE
        };
    ]]
    local infos = parse_enum(enum_str)
    print("enum infos", dump(infos))
    local enums = infos_2_enum(infos)
    print("enums", dump(enums))
end

skynet.start(function()
    simple()
    enum_parse()
    skynet.exit()
end)
