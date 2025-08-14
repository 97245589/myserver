local table, pairs, ipairs = table, pairs, ipairs
local pcall, package, string, require, print, split = pcall, package, string, require, print, split
local SERVICE_NAME = SERVICE_NAME

local skynet = require "skynet"
local lfs = require "lfs"
local load = {
    no_hotload_package = {}
};

load.filenames_from_dir = function(dir_name)
    local arr = {}
    local ok, ret = pcall(lfs.dir, dir_name);
    if not ok then
        return arr
    end
    for file in lfs.dir(dir_name) do
        if file ~= "." and file ~= ".." then
            table.insert(arr, file)
        end
    end
    return arr
end

load.remove_hotreload_package = function()
    for packname, v in pairs(package.loaded) do
        if load.no_hotload_package[packname] then
            -- print("no_hotreload package", packname);
            goto package_reload_continue
        end
        local str_6 = string.sub(packname, 1, 6)
        if "skynet" == str_6 then
            -- print("no_hotreload package", packname);
            goto package_reload_continue
        end

        -- print(SERVICE_NAME, "reload package", packname)
        package.loaded[packname] = nil
        ::package_reload_continue::
    end
end

load.add_no_hotreaload_package = function()
    for packname, v in pairs(package.loaded) do
        -- print("no_hotreload package", packname);
        load.no_hotload_package[packname] = 1
    end
end

load.get_service_dir = function()
    local arr = split(SERVICE_NAME, "/")
    local str = table.concat(arr, "/", 1, #arr - 1)
    return str
end

load.dir_require = function(dir_name)
    -- print("dir_require, ----------", dir_name)
    local t1 = skynet.now()
    local prefix_load_name = string.gsub(dir_name, "/", ".")
    local file_names = load.filenames_from_dir(dir_name)
    for idx, file_name in pairs(file_names) do
        local suffix = string.sub(file_name, -4)
        if ".lua" ~= suffix then
            goto END
        end
        local prefix = string.sub(file_name, 1, #file_name - 4)
        local abs_file = dir_name .. "/" .. prefix
        if abs_file == SERVICE_NAME then
            -- print("no load service -------", abs_file)
            goto END
        end

        local reload_package_name = prefix_load_name .. "." .. prefix;
        require(reload_package_name)
        -- print("package_name", reload_package_name);
        ::END::
    end
    -- print("hotreload cost tm", last_name, skynet.now() - t1);
end

return load
