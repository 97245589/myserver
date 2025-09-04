local require = require
local table, next, pairs = table, next, pairs

local enums = {
    unfinish = 1,
    finish = 2,
    reward = 3,

    player_level = 1
}

local handle = {
    [enums.player_level] = function(player, tevent)
        return player.level
    end
}

local M = {
    enums = enums,
    task_mgrs = {}
}

local gen_event_mark = function(event_arr)
    return table.concat(event_arr, "|", 1, #event_arr - 1)
end

local task_count = function(player, task, tevent, add_num)
    local ep1 = tevent[1]
    if handle[ep1] then
        task.num = handle[ep1](player, tevent) or 0
    else
        task.num = task.num + add_num
    end

    local num = tevent[#tevent]
    if task.num >= num then
        task.num = num
        task.status = enums.finish
        return true
    end
end

local add_event_mark = function(marks, event_mark, taskid)
    marks[event_mark] = marks[event_mark] or {}
    marks[event_mark][taskid] = 1
end

local remove_event_mark = function(marks, event_mark, taskid)
    marks[event_mark][taskid] = nil
    if not next(marks[event_mark]) then
        marks[event_mark] = nil
    end
end

local init_one_task = function(player, task_obj, taskid, tevent)
    local tasks = task_obj.tasks
    if tasks[taskid] then
        return
    end
    local task = {
        id = taskid,
        num = 0,
        status = enums.unfinish
    }
    task_count(player, task, tevent, 0)

    if task.status == enums.unfinish then
        local event_mark = gen_event_mark(tevent)
        add_event_mark(task_obj.marks, event_mark, taskid)
    end
    tasks[taskid] = task
end

M.init_task = function(player, task_obj, task_cfg)
    task_obj.marks = task_obj.marks or {}
    task_obj.tasks = task_obj.tasks or {}

    for taskid, tcfg in pairs(task_cfg) do
        init_one_task(player, task_obj, taskid, tcfg.event)
    end
end

M.count_task = function(player, task_obj, task_cfg, event)
    local event_mark = gen_event_mark(event)
    local taskids = task_obj.marks[event_mark]
    if not taskids or not next(taskids) then
        return
    end

    local t = {}
    local add_num = event[#event]
    for taskid, _ in pairs(taskids) do
        local tevent = task_cfg[taskid].event
        local task = task_obj.tasks[taskid]
        task_count(player, task, tevent, add_num)
        if task.status ~= enums.unfinish then
            remove_event_mark(task_obj.marks, event_mark, task.id)
        end
        table.insert(t, taskid)
    end
    return next(t) and t
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
