require "common.tool.lua_tool"
local require, print, print_v, dump = require, print, print_v, dump
local skynet = require "skynet"
local sproto = require "sproto"
local format = string.format

local compress_cost = function()
    print("compress cost start ===============")
    local zstd = require "common.tool.zstd"
    local obj = {
        arr = {}
    }
    local arr = obj.arr
    for i = 1, 20000 do
        arr[i] = {
            id = i,
            level = i * 10
        }
    end
    local sp = sproto.parse [[
        .Test {
            id 0 : integer
            level 1 : integer
        }
        .Obj {
            arr 0 : *Test(id)
        }
    ]]

    local t = skynet.now()
    local sbin
    for i = 1, 100 do
        sbin = sp:pencode("Obj", obj)
    end
    print("sproto compress:", #sbin, skynet.now() - t)

    t = skynet.now()
    local zbin, zobj
    for i = 1, 100 do
        zbin = zstd.pack(obj)
    end
    print("zstd pack:", #zbin, skynet.now() - t)
end

local encode = function()
    print("encode start ===================")
    local sp = sproto.parse [[
        .Test {
            .Test1 {
                id 0 : integer
                mark 1 : boolean
            }
            id 0 : integer
            name 1 : string
            ids 2 : *double
            tarr 3 : *Test1
            tobj 4 : *Test1(id)
            num 5 : integer
        }
    ]]

    local test = {
        id = 1,
        name = "haha",
        num = "123",
        ids = {2, 1.0, 3.33},
        tarr = {{
            id = 100,
            mark = true
        }, {
            id = 200
        }},
        tobj = {
            [1000] = {
                id = 1000,
                mark = true
            },
            [2000] = {
                id = 2000
            }
        }
    }

    local bin = sp:pencode("Test", test)
    local spobj = sp:pdecode("Test", bin)

    print("objcompare", dump(test, "obj"), dump(spobj, "spobj"))
end

local rpc_test = function()
    print("rpctest start =================")
    local sp = sproto.parse [[
        .package {
            type 0 : integer
            session 1 : integer
        }

        .Test {
            test 0 : integer
        }

        test 1 {
            request {
                req 0 : Test
            }
            response {
                res 0 : integer
            }
        }
    ]]

    local bin = sp:pencode("Test", {
        test = 10
    })
    print("rpc sp decode test", dump(sp:pdecode("Test", bin)))

    local host = sp:host("package")
    local req = host:attach(sp)

    local reqdata = req("test", {
        req = {
            test = 0
        }
    }, 0)
    local pt, name, data, pfunc = host:dispatch(reqdata)
    print("reqdata parse:", pt, name, dump(data), pfunc)
    local resdata = pfunc({
        res = 1
    })
    local pt, session, data = host:dispatch(resdata)
    print("resdata parse:", pt, session, dump(data))

    local t = skynet.now()
    local num = 1e6
    for i = 1, num do
        local _, _, _, res = host:dispatch(reqdata)
        res({
            res = 0
        })
    end
    print(format("hostdispatch %s times cost %s", num, skynet.now() - t))
end

skynet.start(function()
    encode()
    rpc_test()
    compress_cost()
    skynet.exit()
end)
