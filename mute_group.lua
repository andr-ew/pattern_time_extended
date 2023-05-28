-- mute group for multiple pattern_time instances. only one pattern active at a time

local mute_group = {}
mute_group.__index = mute_group

local hook_defaults = {
    pre_clear = function() end,
    post_stop = function() end,
    pre_resume = function() end,
    pre_rec_stop = function() end,
    post_rec_start = function() end,
    pre_rec_start = function() end,
}
hook_defaults.__index = hook_defaults

local silent = true

-- constructor. overwrites hooks for all patterns
function mute_group.new(patterns, hooks)
    local i = {}
    setmetatable(i, mute_group)

    i.patterns = patterns or {}

    i.hooks = setmetatable(hooks or {}, hook_defaults)

    local function stop_all()
        for _,pat in ipairs(i.patterns) do
            pat:rec_stop()
            pat:set_overdub(0)
            pat:stop()
        end
    end

    i.handlers = {
        pre_clear = function() 
            i.hooks.pre_clear()
        end,
        post_stop = function() 
            i.hooks.post_stop()
        end,
        pre_resume = function() 
            stop_all()
            i.hooks.pre_resume()
        end,
        pre_rec_stop = function() 
            i.hooks.pre_rec_stop()
        end,
        pre_rec_start = function() 
            stop_all()
            i.hooks.pre_rec_start()
        end,
        post_rec_start = function() 
            i.hooks.post_rec_start()
        end,
    }

    for _,pat in ipairs(i.patterns) do
        pat:set_all_hooks(i.handlers)
    end

    return i
end

function mute_group:set_hook(name, fn)
    self.hooks[name] = fn
end

function mute_group:set_all_hooks(hooks)
    self.hooks = setmetatable(hooks or {}, hook_defaults)
end

return mute_group
