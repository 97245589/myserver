local print, dump, require, string = print, tdump, require, string
local acts_mgr = require "server.game.player_mgr.mgr.acts_mgr"
local format = string.format

local impls = acts_mgr.impls
impls[10] = {
    open = function(actid)
        print(format("act %s open", actid))
    end,
    close = function(actid)
        print(format("act %s close", actid))
    end
}

