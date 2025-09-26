local require, print, dump, pcall = require, print, dump, pcall
local pairs, table, next = pairs, table, next

local skynet = require "skynet"
local cluster = require "skynet.cluster"
local config = require "common.service.service_config"
local env = require "common.func.env"

local cluster_name = env.clusetr_name()
local host = env.host()
print("clustername :", cluster_name, "cluster_host :", host)

local cluster_node = {}
cluster_node[cluster_name] = host
cluster_node.center1 = config.cluster_node.center1
cluster.reload(cluster_node)
cluster.open(cluster_name)
cluster.register(cluster_name, skynet.self())

local check_diff = function(t1, t2)
    local dels
    for k, v in pairs(t1) do
        if not t2[k] then
            dels = dels or {}
            dels[k] = 1
        end
    end

    local adds
    for k, v in pairs(t2) do
        if not t1[k] then
            adds = adds or {}
            adds[k] = 1
        end
    end
    return {
        adds = adds,
        dels = dels
    }
end

local diff_func
local node_conn_to_center = function()
    local ok, ret = pcall(cluster.call, "center1", "@center1", "heartbeat", cluster_name, host)
    if not ok then
        return
    end

    local diff = check_diff(cluster_node, ret)
    if next(diff) then
        cluster_node = ret
        cluster.reload(cluster_node)
        -- print("diff", dump(diff))
        if diff_func then
            diff_func(diff)
        end
    end
end

skynet.fork(function()
    if "center" ~= env.server_name() then
        while true do
            node_conn_to_center()
            skynet.sleep(300)
        end
    end
end)

return {
    get_cluster_node = function()
        return cluster_node
    end,
    set_diff_func = function(f)
        diff_func = f
    end
}
