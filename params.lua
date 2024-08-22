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

    local function make_ids(i) return {
        start = single and prefix..'_start' or prefix..'_start_'..i,
        resume = single and prefix..'_resume' or prefix..'_resume_'..i,
        stop = single and prefix..'_stop' or prefix..'_stop_'..i,
        clear = single and prefix..'_clear' or prefix..'_clear_'..i,
        time_factor = prefix..'_time_factor',
        reverse = prefix..'_reverse',
        loop = prefix..'_loop',
    } end

    if single then
        o.param_ids = make_ids()
    else
        o.param_ids = {}
        for i,pattern_time in ipairs(o.group) do
            o.param_ids[i] = make_ids(i)
        end
    end

    o.params_count = single and tab.count(o.param_ids) or (3 + (#o.group * 4))

    return o
end

-- function factory:get_filtered_watch(event_index_id)
    --TODO: return a pattern_time:watch method that filters own ids in the event table, at the index specified
-- end

function factory:get_shim(param_setter)
    local param_ids = self.param_ids
    local single = self.typ == 'single'
    local setter = param_setter or function(id, v) params:set(id, v) end

    local function make_shim(pat, ids)
        local sh = setmetatable({}, { 
            -- __index = pat 
            __index = function(t, k)
                return pat[k]
            end,
            __newindex = function(t, k, v)
                pat[k] = v
            end
        })

        sh.is_shim = true

        for _,k in ipairs({ 'start', 'resume', 'stop', 'clear' }) do
            rawset(sh, k, function(self)
                local id = ids[k]
                
                print('shim action: '..k)

                setter(id, params:get(id) ~ 1)
            end)
        end
        rawset(sh, 'set_time_factor', function(self, v)
            setter(ids.time_factor, v)
        end)
        for _,k in ipairs({ 'reverse', 'loop' }) do
            rawset(sh, 'set_'..k, function(self, v)
                setter(ids[k], v > 0)
            end)
        end

        return sh
    end

    local shim
    if single then
        shim = make_shim(self.pattern_time, param_ids)
    else
        shim = {}
        for i,pattern_time in ipairs(self.group) do
            shim[i] = make_shim(pattern_time, param_ids[i])
        end
    end

    return shim
end

function factory:add_params(action)
    local param_ids = self.param_ids
    local single = self.typ == 'single'
    local action = action or function() end

    local function add_playback(pat, ids, name_postfix)
        params:add{
            id = ids.start, name = 'start'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() 
                print('param action: start')
                pat:start(); action() 
            end
        }
        params:add{
            id = ids.resume, name = 'resume'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() 
                print('param action: resume')
                pat:resume(); action() 
            end
        }
        params:add{
            id = ids.stop, name = 'stop'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() 
                print('param action: stop')
                pat:stop(); action() 
            end
        }
        params:add{
            id = ids.clear, name = 'clear'..name_postfix, type = 'binary', behavior = 'trigger',
            action = function() 
                print('param action: clear')
                pat:clear(); action() 
            end
        }
    end

    if single then
        add_playback(self.pattern_time, param_ids, '')
    else
        for i,pattern_time in ipairs(self.group) do
            add_playback(pattern_time, param_ids[i], ' '..i)
        end
    end

    do
        local ids = single and param_ids or param_ids[1]

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
                        pattern_time:set_reverse(v > 0)
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
                        pattern_time:set_loop(v > 0)
                    end
                    action()
                end
            )    
        }
    end
end

return factory
