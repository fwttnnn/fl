--!strict
local Timer = {}
Timer.__index = Timer

function Timer.new()
    local Events = {
        Finished = Instance.new("BindableEvent"),
    }

	return setmetatable({
        Events = Events,
        Finished = Events.Finished.Event,

        Running = false,
        StartTime = 0,
        Duration = 0,
    }, Timer)
end

function Timer:Start(duration, player)
    if self.Running then
        warn("Warning: timer could not start again as it is already running.")
        return
    end

    self.Running = true
    self.Duration = duration
    self.StartTime = tick()

    task.spawn(function()
        while self.Running and tick() - self.StartTime < duration do
            task.wait()
            -- Events.Timer:FireClient(player, self:GetTimeLeft())
        end

        -- NOTE: stopped by other script, we don't want to fire finished.
        if not self.Running then return end

        self:Stop()
        self:Reset()
        self.Events.Finished:Fire()
    end)
end

function Timer:GetTimeLeft()
    if not self.Running then
        warn("Warning: could not get remaining time, timer is not running.")
        return
    end

    local now = tick()
    local timeLeft = self.Duration - (now - self.StartTime)

    if timeLeft < 0 then
        timeLeft = 0
    end

    return timeLeft
end

function Timer:Reset()
    self.StartTime = 0
    self.Duration = 0
end

function Timer:Stop()
    self.Running = false
end

return Timer
