--!strict
local Timer = {}
Timer.__index = Timer

function Timer.new()
    local events = {
        -- Progression = Instance.new("BindableEvent"),
        Progression = {
            Timid = Instance.new("BindableEvent"), -- fires every 1 second
            Tick  = Instance.new("BindableEvent"), -- fires every 0.25 second
        },
        Finished = Instance.new("BindableEvent"),
    }

	return setmetatable({
        Events = events,

        -- NOTE: somehow if we named these events the same as `Events.Timer` (deleted now), it gets
        --       replaced, lmao what a language.
        Progression = {
            Timid = events.Progression.Timid.Event,
            Tick  = events.Progression.Tick.Event,
        },
        Finished = events.Finished.Event,

        Running = false,
        StartTime = 0,
        Duration = 0,
    }, Timer)
end

function Timer:Start(duration)
    if self.Running then
        warn("Timer is already running.")
        return
    end

    self.Running = true
    self.StartTime = tick()

    local nextTick = 0.25
    local nextTimid = 0

    task.spawn(function()
        while self.Running do
            local elapsed = tick() - self.StartTime

            if elapsed >= duration then
                break
            end

            -- Tick every 0.25s
            if elapsed >= nextTick then
                local remaining = math.ceil(duration - elapsed)
                -- self.Events.Progression.Tick:Fire(1 - elapsed / duration)
                self.Events.Progression.Tick:Fire(remaining)
                nextTick = nextTick + 0.25
            end

            -- Timid every 1s
            if elapsed >= nextTimid then
                local remaining = math.ceil(duration - elapsed)
                self.Events.Progression.Timid:Fire(remaining)
                nextTimid = nextTimid + 1
            end


            task.wait(0.05) -- small wait to reduce CPU usage
        end

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
