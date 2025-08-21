local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remote = {
    Event = {
        Act = ReplicatedStorage.Events.Session.Act,
    },
    Function = {
        Act = ReplicatedStorage.Functions.Session.Act,
    },
}

Remote.Event.Act.OnClientEvent:Connect(function()
    -- TODO: show ui, do action.

    -- task.wait(1)
    -- Remote.Function.Act:InvokeServer({Type = "BET", Amount = 100})
end)
