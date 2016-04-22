local EE = {}
EE.__index = EE

function EE:init()
    self.events = {}
end

function EE:on(event,callback)
    self.events[event] = self.events[event] or {}
    self.events[event][#self.events[event] + 1] = {
        callback = callback,
        type = "on"
    }
end

function EE:once(event,callback)
    self.events[event] = self.events[event] or {}
    self.events[event][#self.events[event] + 1] = {
        callback = callback,
        type = "once"
    }
end

function EE:emit(event,...)
    self.events[event] = self.events[event] or {}

    local indicesToRemove = {}
    for i,callbackData in ipairs(self.events[event]) do
        local suc = xpcall(callbackData.callback,function(err)
            ErrorNoHalt(err.."\n"..debug.traceback().."\n")
        end,...)

        if callbackData.type == "once" then
            indicesToRemove[#indicesToRemove + 1] = i - #indicesToRemove
        end
    end

    for i,idx in ipairs(indicesToRemove) do
        table.remove(self.events[event],iidx)
    end
end

function Sonus.lib.NewEventEmitter()
    local instance = setmetatable({},EE)
    instance:init()
    return instance
end
