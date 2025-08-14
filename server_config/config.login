ip = "$IP"
cluster_port = 10300
gate_port = 10301
debug_console_port = 10302
server_name = "login"
server_id = 1

thread = 8
harbor = 0
start = "server/main"	-- main script
luaservice = "skynet/service/?.lua;?.lua"
lualoader = "skynet/lualib/loader.lua"
lua_path = "skynet/lualib/?.lua;?.lua"
lua_cpath = "skynet/luaclib/?.so;luaclib/?.so"
cpath = "skynet/cservice/?.so"

--logger = "run/" .. server_name .. server_id .. ".log"
--daemon = "run/" .. server_name .. server_id .. ".pid"