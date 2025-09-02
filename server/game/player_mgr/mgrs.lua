local pairs = pairs

local M = {}

local mgrs = {}
local ticks = {}

M.add = function(name, module)
    mgrs[name] = module
    if module.tick then
        ticks[name] = module.tick
    end
end

M.tick = function()
    for k, func in pairs(ticks) do
        func()
    end
end

M.dbdata = {}

return M
