local require = require
local table, next, pairs = table, next, pairs

local enums = {
    unfinish = 1,
    finish = 2,
    reward = 3,

    player_level = 1
}

local handle = {
    [enums.player_level] = function(player, tevent, task)
        return player.level
    end
}

local M = {
    enums = enums,
    task_mgrs = {}
}

local count_task = function(player, task, tevent, add_num)
    local change
    local ep1 = tevent[1]
    if handle[ep1] then
        local bnum = task.num
        task.num = handle[ep1](player, tevent, task) or 0
        if bnum ~= task.num then
            change = true
        end
    else
        task.num = task.num + add_num
        if add_num ~= 0 then
            change = true
        end
    end

    local num = tevent[#tevent]
    if task.num >= num then
        task.num = num
        task.status = enums.finish
    end
    return change
end

M.init_task = function(player, task_obj, task_cfg)
    task_obj.marks = task_obj.marks or {}
    task_obj.tasks = task_obj.tasks or {}

    local tasks = task_obj.tasks
    local marks = task_obj.marks
    for taskid, tcfg in pairs(task_cfg) do
        local tevent = tcfg.event
        if tasks[taskid] then
            goto cont
        end
        local task = {
            id = taskid,
            num = 0,
            status = enums.unfinish
        }
        count_task(player, task, tevent, 0)
        if task.status == enums.unfinish then
            local emark = tevent[1]
            marks[emark] = marks[emark] or {}
            marks[emark][taskid] = 1
        end
        tasks[taskid] = task
        ::cont::
    end
end

M.count_task = function(player, task_obj, task_cfg, event)
    local emark = event[1]
    local marks = task_obj.marks
    local taskids = marks[emark]
    if not taskids or not next(taskids) then
        return
    end

    local arr = {}
    local add_num = event[#event]
    for taskid, _ in pairs(taskids) do
        local tevent = task_cfg[taskid].event
        local task = task_obj.tasks[taskid]
        local change = count_task(player, task, tevent, add_num)
        if change then
            table.insert(arr, taskid)
        end
        if task.status ~= enums.unfinish then
            marks[emark][taskid] = nil
            if not next(marks[emark]) then
                marks[emark] = nil
            end
        end
    end
    return next(arr) and arr
end

M.trigger_event = function(player, pevent)
    for name, mgr in pairs(M.task_mgrs) do
        mgr.trigger_event(player, pevent)
    end
end

M.add_taskmgr = function(name, mgr)
    M.task_mgrs[name] = mgr
end
M.del_taskmgr = function(name)
    M.task_mgrs[name] = nil
end

return M
