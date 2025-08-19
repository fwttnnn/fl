--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Act = ReplicatedStorage.Events.Session.Act,
}

local Managers = ServerStorage:WaitForChild("Managers")
local SessionManager = require(Managers.Session)

Events.Act.OnServerEvent:Connect(function(player, action)
    local session = SessionManager.FindPlayerSession(player)
    session:Act(player, action)
end)
