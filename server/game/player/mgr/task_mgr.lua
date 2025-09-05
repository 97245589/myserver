local require, print = require, print
local table, next, pairs = table, next, pairs
local mgrs = require "server.game.player.mgrs"
local enums = require "common.func.enums"

local handle

local M = {
    set_handle = function(h)
        handle = h
    end,
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
            status = enums.task_unfinish
        }
        count_task(player, task, tevent, 0)
        if task.status == enums.task_unfinish then
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
    local tasks = task_obj.tasks
    for taskid, _ in pairs(taskids) do
        local cfg = task_cfg[taskid]
        if not cfg then
            print("count task error no cfg", taskid)
            goto cont
        end
        local tevent = cfg.event
        local task = tasks[taskid]
        local change = count_task(player, task, tevent, add_num)
        if change then
            table.insert(arr, taskid)
        end
        if task.status ~= enums.task_unfinish then
            marks[emark][taskid] = nil
            if not next(marks[emark]) then
                marks[emark] = nil
            end
        end
        ::cont::
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

mgrs.add_mgr("task_mgr", M)
return M
