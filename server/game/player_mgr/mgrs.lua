local pairs = pairs

local M = {}

local mgrs = {}
local ticks = {}
local start_timeouts = {}

M.add = function(name, module)
    mgrs[name] = module
    if module.tick then
        ticks[name] = module.tick
    end
    if module.start_timeout then
        start_timeouts[name] = module.start_timeout
    end
end

M.tick = function()
    for k, func in pairs(ticks) do
        func()
    end
end

M.start_timeout = function()
    for k, func in pairs(start_timeouts) do
        func()
    end
end

M.dbdata = {}

return M
