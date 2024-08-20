-- param factory for pattern_time instances

local factory = {}

function factory:new(prefix, typ, pattern_time)
    local o = setmetatable({}, self)
    self.__index = self

    local single = typ == 'single'

    o.prefix = prefix
    o.typ = typ
    if single then o.pattern_time = pattern_time
    else o.group = pattern_time
    end

    o.param_ids = {
        start = single and prefix..'_start' or {},
        resume = single and prefix..'_resume' or {},
        stop = single and prefix..'_stop' or {},
        clear = single and prefix..'_clear' or {},
        time_factor = prefix..'_time_factor',
        reverse = prefix..'_reverse',
        loop = prefix..'_loop',
    }

    if o.group then
        for i,pattern_time in ipairs(o.group) do
            o.param_ids.start[i] = prefix..'_start_'..i
            o.param_ids.resume[i] = prefix..'_resume_'..i
            o.param_ids.stop[i] = prefix..'_stop_'..i
            o.param_ids.clear[i] = prefix..'_clear_'..i
        end
    end

    o.params_count = single and tab.count(o.param_ids) or (3 + (#o.group * 4))

    return o
end

function factory:get_filtered_watch(event_index_id)
    --TODO: return a pattern_time:watch method that filters own ids in the event table, at the index specified
end

function factory:add_params(action)
    local ids = self.param_ids
    local single = self.typ == 'single'
    local action = action or function() end

    local function add_playback(pat, id_st, id_re, id_stop, id_clear, name_postfix)
        params:add{
            id = id_st, name = 'start'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() pat:start(); action() end
        }
        params:add{
            id = id_re, name = 'resume'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() pat:resume(); action() end
        }
        params:add{
            id = id_stop, name = 'stop'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() pat:stop(); action() end
        }
        params:add{
            id = id_clear, name = 'clear'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() pat:clear(); action() end
        }
    end

    if single then
        add_playback(self.pattern_time, ids.start, ids.resume, ids.stop, ids.clear, '')
    else
        for i,pattern_time in ipairs(self.group) do
            add_playback(
                pattern_time, ids.start[i], ids.resume[i], ids.stop[i], ids.clear[i], ' '..i
            )
        end
    end

    local function get_factor(v)
        return (v >= 0) and (1/(v + 1)) or (-(v - 1))
    end

    params:add{
        id = ids.time_factor, name = 'time factor', type = 'number',
        min = -100, max = 100, default = 0,
        action = (
            single and function(v) pattern_time.time_factor = get_factor(v); action() end
            or function(v)
                local f = get_factor(v)
                for i,pattern_time in ipairs(self.group) do
                    pattern_time.time_factor = f 
                end
                action()
            end
        )    
    }
    params:add{
        id = ids.reverse, name = 'reverse', type = 'binary', behavior = 'toggle', default = 0,
        action = (
            single and function(v) pattern_time:set_reverse(v); action() end
            or function(v)
                for i,pattern_time in ipairs(self.group) do
                    pattern_time:set_reverse(v)
                end
                action()
            end
        )    
    }
    params:add{
        id = ids.loop, name = 'loop', type = 'binary', behavior = 'toggle', default = 1,
        action = (
            single and function(v) pattern_time:set_loop(v); action() end
            or function(v)
                for i,pattern_time in ipairs(self.group) do
                    pattern_time:set_loop(v)
                end
                action()
            end
        )    
    }
end

return factory
