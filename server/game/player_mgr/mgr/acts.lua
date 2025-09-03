local print, dump, require = print, tdump, require
local acts_mgr = require "server.game.player_mgr.mgr.acts_mgr"
local impls = acts_mgr.impls

impls[10] = {
    create = function(act)
        -- print("act 10 create")
    end,
    open = function(act)
        -- print("act 10 start")
    end,
    close = function(act)
        -- print("act 10 closed")
    end
}

