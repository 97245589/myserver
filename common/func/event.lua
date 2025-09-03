local pairs = pairs

local M = {}

local events = {}

M.reg = function(eve, name, func)
    events[eve] = events[eve] or {}
    events[eve][name] = func
end

M.trigger = function(eve, ...)
    if not events[eve] then
        return
    end
    for name, func in pairs(events[eve]) do
        func(...)
    end
end

return M
