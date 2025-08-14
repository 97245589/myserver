ip = "$IP"
cluster_port = 10300
gate_port = 10301
debug_console_port = 10302
server_name = "login"
server_id = 1

root = "./"
thread = 8
harbor = 0
start = "server/main"	-- main script
luaservice = root .. "skynet/service/?.lua;" .. root .. "/?.lua;"
lualoader = root .. "skynet/lualib/loader.lua"
lua_path = root .. "skynet/lualib/?.lua;" .. root .. "/?.lua;"
lua_cpath = root .. "skynet/luaclib/?.so;" .. root .. "luaclib/?.so"
cpath = root.."/skynet/cservice/?.so"

--logger = "run/" .. server_name .. server_id .. ".log"
--daemon = "run/" .. server_name .. server_id .. ".pid"